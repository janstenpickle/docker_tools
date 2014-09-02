# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'docker_tools/version'

Gem::Specification.new do |spec|
  spec.name          = "docker_tools"
  spec.version       = DockerTools::VERSION
  spec.authors       = ["Chris Jansen"]
  spec.email         = ["noone@nowhere.com"]
  spec.description   = %q{Wrapper around ruby docker API to help with builds and stuff}
  spec.summary       = %q{See desc}
  spec.homepage      = "https://github.com/janstenpickle/docker_tools"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "bundler", "~> 1.3"
  spec.add_dependency "rake"
  spec.add_dependency "docker-api", "= 1.13.2"
  spec.add_dependency "erubis"
  spec.add_dependency "json"
end
