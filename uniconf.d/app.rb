upup = File.expand_path('../../', __FILE__)
module Hipe; end
module Uniconf; end
require "#{upup}/hipe-tinyscript/core" unless Hipe.const_defined? :Tinyscript
require 'open3'
require 'fileutils'

Uniconf::Config = {
  :git => 'git://git.bogomips.org/unicorn.git'
}


module Uniconf

  class MyCommand < Hipe::Tinyscript::Command; end
  class MyTask < Hipe::Tinyscript::Task
    def baktix cmd, name, error_ok=false # total abstraction candidate
      out colorize('running: ', :green) << cmd
      status = nil
      unless dry_run?
        Open3.popen3(cmd) do |sin, sout, serr|
          o = ''; e = nil
          while o || e do
            out "#{name}: #{o}" if o && o = sout.gets
            if ! o && e = serr.gets
              status = :baktix_error unless error_ok
              if error_ok
                out "#{name}: #{o}" if o && o = sout.gets
              else
                puts colorize("#{name} error: ", :red) << e
              end
            end
          end
        end
      end
      status
    end
    def soft_error msg
      out colorize("error: ", :red) << msg
      return :soft_error
    end
  end

  module Tasks
    class PullTarball < MyTask
      parameter :build_dir, "where to put the build files", :default => './src' # copy pasted elsewhere
      def run
        src = param(:build_dir)
        target = File.join(src, 'unicorn')
        if File.exist?(target)
          out colorize('exists: ', :green) << "#{target}. skipping git clone. (you could git pull tho.)"
          return nil
        end
        FileUtils.mkdir(src, :verbose => 1, :noop => dry_run?) unless File.exist?(src)
        return :build_directory_not_present unless File.exist?(src) || dry_run? # careful
        baktix "git clone #{param(:git)} #{target}", 'git'
      end
    end
    class Install < MyTask
      parameter :build_dir, "where to put the build files", :default => './src' # copy pasted elsewhere
      parameter '--rvm-ok', "provide this required flag to indicate that you are using the correct rvm gemset."
      def run
        return soft_error("indicate --rvm-ok to show that you have dealt with rvm") unless @param.key? :rvm_ok
        dizzle = File.join(param(:build_dir), 'unicorn')
        return :unicorn_dir_not_found unless File.directory? dizzle
        FileUtils.cd(dizzle, :verbose => 1) do
          out "what you could do by hand is:\nruby setup.rb config\nruby setup.rb make\nruby setup.rb install"
          out "hey by the way i had to manually install gems: 'rack', 'kgio'"
          out colorize("meh nevermind just gem install! :(", :yellow)
          #baktix 'ruby setup.rb', 'ruby setup', :error_ok
        end
      end
    end
  end
  module Commands
    class Install < MyCommand
      description "clone bleeding edge unicorn http server and install it."
      parameter '-n', '--dry-run', "don't actually do anything, shows a preview"
      tasks :pull_tarball, :install
    end
  end
  class App < Hipe::Tinyscript::App
    description "do things related to unicorn configuration and installation"
    commands Commands
    config Config
  end
end
