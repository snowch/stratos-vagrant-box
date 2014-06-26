require "stratos/version"

module Stratos
  class Plugin < Vagrant.plugin("2")
    name "stratos plugin"
    command "stratos" do
      require_relative "command"
      Command
    end
  end
end
