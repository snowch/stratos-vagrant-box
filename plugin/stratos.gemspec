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

  gem.files         = [".gitignore", 
			"Gemfile", 
			"LICENSE", 
			"LICENSE.txt", 
			"README.md", 
			"Rakefile", 
			"build_plugin.sh", 
			"install_ruby_plugin_dev_env.sh", 
			"lib/command.rb", 
			"lib/command_util.rb", 
			"lib/stratos.rb", 
			"lib/stratos/version.rb", 
			"pkg/stratos-0.0.1.gem", 
			"stratos.gemspec", 
			"test"
			]
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
