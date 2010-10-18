#!/usr/bin/env ruby

# require 'rubygems'; require 'ruby-debug'; puts "\e[1;5;33mruby-debug\e[0m"

# don't rely on rubygems to avoid pulling in the library redundantly
module Hipe; end
me = File.dirname(__FILE__)
require "#{me}/hipe-tinyscript/core.rb" unless Hipe.const_defined? 'Tinyscript'
require "#{me}/hipe-tinyscript/support.rb" unless Hipe::Tinyscript.const_defined? 'Support'
require 'open3'

module RoxConf; end
RoxConf::Conf = {
  # relative paths will be relative to **this __FILE__** ! not pwd
  :apps => [
    { :path => 'confconf' },
    { :path => 'userconf' },
    { :path => 'redconf' },
    { :path => 'monitconf.d/monitconf'},
    { :path => '/etc/thin/thinconf' },
    { :path => '/var/sites/redmine-aha/current/scripts/mineconf' },
    { :path => '<%= home %>/gitolite-admin/repoconf', :git => 'git@hipeland.org:gitolite-admin'}
  ]
}

module Hipe::Tinyscript
  # experimental home, might be moved
  module MultiplexMethods
    def expand_app_path path
      if path[0] == '/'
        path
      elsif path.index('<%=')
        @app_path_vars ||= Hipe::Tinyscript::Support::ClosedStruct.new(:home => proc{ ENV['HOME'] })
        Hipe::Tinyscript::Support::Template.new(path).interpolate(@app_path_vars)
      else
        File.expand_path(path, File.dirname(__FILE__))
      end
    end
  end

  FOUR = 4
  class MultiplexCommand < Hipe::Tinyscript::App::DefaultCommand # oh boy
    def initialize *a
      super(*a)
      @flatten_commands = true # on display etc
    end
    def show_maybe_command_help cmd=nil
      throw :app_interrupt, [:show_command_specific_help, cmd] unless cmd.nil? # just yes
      matrix = []
      @app.commands.each do |c|
        matrix.push [c.short_name, c.desc_oneline]
      end
      @app.child_app_classes.sort{|a,b| a.program_name <=> b.program_name }.each do |app_cls|
        app_cls.new.commands.each do |c| # ich muss sein
          matrix.push ["#{app_cls.program_name} #{c.short_name}", c.desc_oneline]
        end
      end
      t = tableize(matrix)
      new_col1_width = [ t.width(0) + FOUR, option_parser.summary_width ].max
      option_parser.summary_width = new_col1_width
      out option_parser.help
      out colorize('commands:', :bright, :green)
      if t.rows.any?
        whitespace = ' ' * (FOUR + FIXME)
        fmt = "    %#{t.width(0)}s#{whitespace}%-#{t.width(1)}s"
        t.rows.each{ |colA, colB| out sprintf(fmt, colA, colB) }
      end
      :interrupt_handled
    end
  end

  # make it look like an app for some purposes
  class AppStub
    def initialize info
      @info = info
    end
    def short_name
      File.basename(@app[:path])
    end
  end

  class MultiplexApp < App
    include MultiplexMethods
    default_command_class MultiplexCommand
    attr_reader :app
    def child_app_classes
      @child_app_classes ||= config[:apps].map{ |app| load_app_class(app) }.compact
    end
    def load_app_class app_info
      path = expand_app_path(app_info[:path])
      return on_missing_app_file(path) if ! File.exist?(path)
      sz1 = Hipe::Tinyscript::App.subclasses.size
      # out colorize('loading: ', :blink, :bright, :yellow) << path
      load path # can't require, it requires an '*.rb'
      sz2 = Hipe::Tinyscript::App.subclasses.size
      return on_failed_to_determine_app_class(path, sz1, sz2) unless 1 == ( sz2 - sz1 )
      cls = Hipe::Tinyscript::App.subclasses.last
      cls.program_name = File.basename(path) # es muss sein
      cls
    end
    # you're guaranteed that argv has a first arg is a non-switch arg
    def find_commands argv
      cmds = super(argv)
      return cmds if cmds.any? # it makes life suck not doing this.
      command_str = argv.first # no who hah net
      re = Regexp.new("^#{Regexp.escape(command_str)}")
      infos = config[:apps].select{ |a| re =~ File.basename(a[:path]) }
      if infos.size > 1 && (ai = infos.detect{ |a| command_str == File.basename(a[:path])} )
        infos = [ai]
      end
      infos.size == 1 ? [load_app_class(infos.first)] : infos.map{ |i| AppProxy.new(i) }
    end
  protected
    def run_command cmd_or_app_class, argv
      if cmd_or_app_class.instance_method(:run).arity == 1
        cmd_or_app_class.new.run(argv.slice(1..-1))
      else
        super(cmd_or_app_class, argv)
      end
    end
  private
    def on_missing_app_file path
      out colorize('notice: ', :yellow) << "not found: #{path}"
      nil
    end
    def on_failed_to_determine_app_class path, sz1, sz2
      case sz2 - sz1
      when 0
        out colorize("notice: ", :yellow) << "File does not define any immediate subclasses of ::App? #{path}"
      else
        out colorize("notice: ", :yellow) << "File defines more than one (#{sz2-sz1}) subclasses of ::App: #{path}"
      end
      nil
    end
  end
end

module RoxConf
  class MyCommand < Hipe::Tinyscript::Command; end
  module Commands
    class Check < MyCommand
      include Hipe::Tinyscript::MultiplexMethods
      description "check that conf apps are installed"
      def execute
        @param[:apps].each do |info|
          path = expand_app_path(info[:path])
          if File.exist?(path)
            out colorize('ok: ', :bright, :green) << path
          else
            out colorize('missing: ', :bright, :red) << path
          end
        end
      end
    end
    class Install < MyCommand
      include Hipe::Tinyscript::MultiplexMethods
      description "where possible try to install roxconf child scripts with git"
      parameter '-n', '--dry-run', "don't actually install anything"
      def execute
        @param[:apps].each do |info|
          path = expand_app_path info[:path]
          if File.exist? path
            out colorize('exists: ', :bright, :green) << path
          else
            try_install info
          end
        end
        nil
      end
    private
      def try_install info
        path = expand_app_path info[:path]
        if ! info.key?(:git)
          out colorize('notice: ', :yellow) << "no git info known about #{path}. can't install."
          return :no_git_info
        end
        one_level_up = File.dirname path
        two_level_up = File.dirname one_level_up
        if File.exist?(one_level_up)
          out colorize('notice: ') << "can't install. dir already exists: #{one_level_up}"
          return :dir_exists
        end
        if ! File.exist?(two_levels_up)
          out colorize('notice: ') << "can't install. dir must already exist: #{two_levels_up}"
          return :dir_doesnt_exist
        end
        cmd = "git clone #{info[:git]} #{one_level_up}"
        out colorize('git: ') << cmd
        status = nil;
        if ! dry_run?
          o = ''; e = nil
          Open3.popen3(cmd) do |sin, sout, serr|
            while o || e do
              out o if o && o = sout.gets
              if ! o && e = serr.gets
                status = :git_error
                out colorize('git err: ', :red) << e
              end
            end
          end
        end
        status || submodules_init(one_level_up)
      end
      def submodules_init one_level_up
        cmds = ['git submodule init', 'git submodule sync', 'git submodule update']
        if dry_run?
          out "cd #{one_level_up}"
          out cmds
          out "cd -"
        else
          FileUtils.cd(one_level_up) do
            cmds.each do |cmd|
              o = ''; e = nil
              Open3.popen3(cmd) do |ii, oo, ee|
                while o || e
                  puts o if o && o = oo.gets
                  puts colorize("submod err: ", :red) if ! e && e = ee.gets
                end
              end
            end
          end
        end
        nil
      end
    end
  end
end

module RoxConf
  class App < Hipe::Tinyscript::MultiplexApp
    config Conf
    commands Commands
  end
end
