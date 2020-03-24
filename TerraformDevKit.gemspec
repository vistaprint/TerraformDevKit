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

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'webmock'
  
  spec.add_runtime_dependency 'aws-sdk-core'
  spec.add_runtime_dependency 'aws-sdk-dynamodb'
  spec.add_runtime_dependency 'aws-sdk-cloudfront'
  spec.add_runtime_dependency 'aws-sdk-s3'
  spec.add_runtime_dependency 'mustache'
  spec.add_runtime_dependency 'rainbow'
  spec.add_runtime_dependency 'rubyzip'
end
