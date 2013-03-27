# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano-nvie-git-workflow/version'

Gem::Specification.new do |gem|
  gem.name          = "capistrano-nvie-git-workflow"
  gem.version       = CapistranoNvieGitWorkflow::VERSION
  gem.authors       = ["Steve Valaitis"]
  gem.email         = ["steve@digitalnothing.com"]
  gem.description   = %q{Provides Capistrano tasks to deploy using the git workflow described in http://nvie.com/posts/a-successful-git-branching-model}
  gem.summary       = %q{Capistrano tasks for the NVIE git workflow}
  gem.homepage      = "http://github.com/dnd/capistrano-nvie-git-workflow"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "capistrano", "~> 2.0"
  gem.add_dependency "cap_git_tools", "~> 0.9"
end
