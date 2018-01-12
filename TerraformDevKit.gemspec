# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'TerraformDevKit/version'

Gem::Specification.new do |spec|
  spec.name          = 'TerraformDevKit'
  spec.version       = TerraformDevKit::VERSION
  spec.authors       = ['Victor Jimenez']
  spec.email         = ['vjimenez@vistaprint.com']

  spec.summary       = 'Set of scripts to ease development and testing with Terraform.'
  spec.homepage      = 'https://github.com/vistaprint/TerraformDevKit'
  spec.license       = 'Apache-2.0'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'webmock', '~> 3.0'

  spec.add_runtime_dependency 'aws-sdk-core', '~> 3'
  spec.add_runtime_dependency 'aws-sdk-dynamodb', '~> 1'
  spec.add_runtime_dependency 'aws-sdk-s3', '~> 1'
  spec.add_runtime_dependency 'mustache', '~> 1.0'
  spec.add_runtime_dependency 'rainbow', '~> 3.0'
  spec.add_runtime_dependency 'rubyzip', '~> 1.2'
end
