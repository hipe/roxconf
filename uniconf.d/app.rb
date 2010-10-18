upup = File.expand_path('../../', __FILE__)
module Hipe; end
require "#{upup}/hipe-tinyscript/core" unless Hipe.const_defined? :Tinyscript

module Uniconf
  class MyCommand < Hipe::Tinyscript::Command; end
  module Commands
    class Install < MyCommand
      description "shows a preview of what will be done."
      parameter '-n', '--dry-run', "don't actually do anything, shows a preview"
    end
  end
  class App < Hipe::Tinyscript::App
    description "do things related to unicorn configuration and installation"
    commands Commands
  end
end
