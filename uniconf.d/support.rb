upup = File.expand_path('../../', __FILE__)
module Hipe; end
require "#{upup}/hipe-tinyscript/core" unless Hipe.const_defined? :Tinyscript
require "#{upup}/hipe-tinyscript/support" unless Hipe::Tinyscript.const_defined? :Support

module Uniconf
  # if this gets at all non trivial consider moving it to thinconf
  # it's for letting unicorn have config files that read thin config files
  #
  class ThinConfigFile < Hipe::Tinyscript::Support::ConfFile
    class << self
      def at path
        file = new{ |f| f.parse_file path }
        (err = file.validate) ?
          ( $stderr.puts("error parsing #{path.inspect}: #{err}") && nil ) :
          file
      end
    end
    %w(chdir).each{ |m| define_method(m){value(m)} }
    %w(port timeout).each{ |m| define_method(m){ value(m).to_i } }
    def pid_dir
      File.join(value('chdir'), File.dirname(value('pid')))
    end
    def log_dir
      File.join(value('chdir'), File.dirname(value('log')))
    end
  end
end
