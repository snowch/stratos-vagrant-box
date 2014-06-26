# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'stratos/version'

Gem::Specification.new do |gem|
  gem.name          = "stratos"
  gem.version       = Stratos::VERSION
  gem.authors       = ["Chris Snow"]
  gem.email         = ["chsnow@apache.org"]
  gem.description   = %q{plugin for the stratos vagrant box}
  gem.summary       = %q{plugin for the stratos vagrant box}
  gem.homepage      = ""

  gem.add_development_dependency "rake"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
