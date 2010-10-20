require 'fileutils'
module Hipe; end
Hipe.const_defined?(:Tinyscript) or require File.expand_path('../../hipe-tinyscript/core', __FILE__)
Hipe::Tinyscript.const_defined?(:Support) or require File.expand_path('../../hipe-tinyscript/support', __FILE__)

module PassengerConf
  Conf = {
    :blah => [
      {:src => '/etc/roxconf/servers/hipeland/etc/nginx/nginx.conf', :dst => '/etc/nginx/nginx.conf'}
    ]
  }
end

module PassengerConf
  class MyCommand < Hipe::Tinyscript::Command
    include Hipe::Tinyscript::Support::FileyCoyote
  end
  module Commands
    class Install < MyCommand
      description "gem install who-hah"
      parameter '-n', '--dry-run', 'blah blah'
      parameter :did_phusion, '-Y', "you did install phusion already"
      def execute
        if st = execute_with_status
          out "didn't complete: #{st.inspect}"
          st
        end
      end
      def execute_with_status
        st = install_gem and return st
        (st = phusion_interactive and return st) unless @param.key? :did_phusion
        st = do_simmy(@param[:blah][0][:src], @param[:blah][0][:dst], true) and return st
      end
    private
      def do_simmy full_src, tgt, move_to_backup = false
        do_symlink = true
        if File.exist?(tgt) || File.symlink?(tgt) # catches bad symlinks
          do_symlink = false
          if File.symlink?(tgt)
            actual_src = File.readlink(tgt) # http://ruby-doc.org/core/classes/File.src/M002534.html
            if actual_src == full_src
              out colorize('ok: ', :green) << "#{tgt} -> #{full_src}"
            else
              out colorize('notice: ', :yellow) << "#{tgt} -> #{actual_src} (! #{full_src})"
              if ! File.exist?(tgt)
                out colorize('notice: ', :yellow) <<
                  "#{colorize(tgt, :magenta)} -> #{actual_src} (target path does not exist)"
              end
            end
          else
            out colorize('notice: ', :yellow) << "not a symlink: #{tgt}"
            if move_to_backup
              make_backup tgt
              FileUtils.rm(tgt, :verbose => true, :noop => dry_run?)
              do_symlink = true
            end
          end
        end
        if do_symlink
          FileUtils.ln_s(full_src, tgt, :verbose => 1, :noop => dry_run?)
        end
        nil
      end
      def phusion_interactive
        out "run this: " << colorize('passenger-install-nginx-module', :bright, :green)
        out "did it go and are you happy with it? (yes/{other})"
        str = $stdin.gets.chomp
        return :do_phusion if 'yes' != str
        nil
      end
      def install_gem
        found = false
        st = baktix("#{File.join(File.dirname(__FILE__), 'gem-list.sh')}") do |bt|
          found; # necessary to propagate it down to the next scope below
          bt.dry{ } # it's ok to keep going after this when dry run
          bt.out{ |line| out colorize('bash a: ', :green) << line;  found ||= (/\Apassenger / =~ line)}
          bt.err{ |line| err colorize('err: ', :red)    << line }
        end and return st
        found and return nil
        baktix("#{File.join(File.dirname(__FILE__), 'gem-install.sh')}") do |bt|
          bt.dry{ } # it's ok to keep going after this when dry run
          bt.out{ |line| out colorize('bash: ', :green) << line }
          bt.err{ |line| err colorize('err: ', :red)    << line }
        end
      end
    end
  end
  class App < Hipe::Tinyscript::App
    commands Commands
    config Conf
  end
end
