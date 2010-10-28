module Hipe; end
require 'fileutils'

require File.dirname(__FILE__)+'/../hipe-tinyscript/core' unless Hipe.const_defined? :Tinyscript
require File.dirname(__FILE__)+'/../hipe-tinyscript/support' unless Hipe::Tinyscript.const_defined? :Support

module RubyEeConf
  Conf = {
    :tarball => 'http://rubyforge.org/frs/download.php/71096/ruby-enterprise-1.8.7-2010.02.tar.gz',
    :dir => 'ruby-ee'
  }
  class MyCommand < Hipe::Tinyscript::Command
    def outfile
      File.join(sourcedir, File.basename(param(:tarball)))
    end
    def sourcedir
      param :src
    end
    def tarball
      param :tarball
    end
    def extract_dir
      sourcedir
    end
    def extract_result
      File.join(extract_dir, File.basename(param(:tarball), '.tar.gz'))
    end
  end
  module Commands
    class Install < MyCommand
      description "installs ruby enterprise edition: wget, tar, run."
      parameter :src, '--source-dir DIR', "build it here", :default => 'src'
      parameter '-n', '--dry-run'
      def execute
        if status = get_tarball || extract || install
          out "didn't do something: #{status.inspect}"
        end
        status
      end
    private
      def get_tarball
        if ! File.directory? sourcedir
          FileUtils.mkdir_p(sourcedir, :verbose => true, :noop => dry_run?)
        end
        puts "checking: #{outfile}"
        if File.exists? outfile
          out colorize("using: ", :green) << outfile
          return nil
        end
        baktix("wget -O #{outfile} #{tarball}") do |std|
          std.out{ |s| out colorize('wget: ', :green) << s }
          std.err{ |s| out colorize('wget: ', :red) << s } # this one usually
        end
        nil # otherwise above returns :stderr_written
      end
      def extract
        # tar writes to stderr and hands when we try to read stdout
        if File.directory? extract_result
          out colorize('using: ', :green) << extract_result
          return nil
        end
        FileUtils.mkdir_p(extract_dir, :verbose => 1, :noop => dry_run?)
        baktix("tar -xzvf #{outfile} -C #{extract_dir} 2>&1") do |std|
          std.out{ |s| out colorize("tar: ", :green) << s }
        end
        nil
      end
      def install
        cmd = "#{extract_result}/installer"
        out "try running the following. good luck!\n#{cmd}"
        return :run_the_interactive_installer
        baktix() do |std|
          # std.out{ |s| out colorize('ree: ', :green) << s }
          std.err{ |s| out colorize('ree: ', :red)   << s }
        end
      end
    end
  end
  class App < Hipe::Tinyscript::App
    config Conf
    commands Commands
    description "do stuff with Ruby Enterprise Edition"
  end
end
