require 'ruby-debug'; puts "\e[1;5;33mruby-debug\e[0m"
module Hipe; end
me = File.dirname(__FILE__)
require "#{me}/hipe-tinyscript/core.rb" unless Hipe.const_defined? 'Tinyscript'
require "#{me}/hipe-tinyscript/support.rb" unless Hipe::Tinyscript.const_defined? 'Support'
require "#{me}/hipe-tinyscript/support/multiplex"
require 'open3'

module RoxConf; end
require File.dirname(__FILE__) + '/conf'

module RoxConf
  class MyCommand < Hipe::Tinyscript::Command; end
  module Commands
    class Check < MyCommand
      attr_writer :app
      description "check that conf apps are installed"
      def execute
        @app.app_infos.each do |ai|
          if ai.valid?
            out colorize('ok: ', :bright, :green) << ai.path_interpolated
          else
            ai.errors.each do |e|
              out colorize('issue: ', :brigt, :red) << e.message
            end
          end
        end
      end
    end
    class Install < MyCommand
      attr_writer :app
      description "where possible try to install roxconf child scripts with git"
      parameter '-n', '--dry-run', "don't actually install anything"
      def execute
        @app.app_infos.select{ |ai| ai.key?(:git) }.each do |ai|
          if ! ai.key? :cd
            out colorize('notice: ', :yellow) << "what to do without cd? #{ai.path_interpolated}"
            next
          end
          if File.exist? ai.path_dirname
            out colorize('exists: ', :bright, :green) << ai.path_dirname
          else
            try_install ai
          end
        end
        nil
      end
    private
      def try_install info
        if ! info.key?(:git)
          out colorize('notice: ', :yellow) << "no git info known about #{path}. can't install."
          return :no_git_info
        end
        one_level_up = info.path_dirname
        two_level_up = File.dirname one_level_up
        if File.exist?(one_level_up)
          out colorize('notice: ') << "can't install. dir already exists: #{one_level_up}"
          return :dir_exists
        end
        if ! File.exist?(two_levels_up)
          out colorize('notice: ') << "can't install. dir must already exist: #{two_levels_up}"
          return :dir_doesnt_exist
        end
        cmd = "git clone #{info.git} #{one_level_up}"
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
  class App < Hipe::Tinyscript::Support::Multiplex::App
    config Conf
    commands Commands
  end
end
