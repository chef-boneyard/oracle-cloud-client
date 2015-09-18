# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'oracle-cloud/version'

Gem::Specification.new do |spec|
  spec.name          = 'oracle-cloud'
  spec.version       = OracleCloud::VERSION
  spec.authors       = ['Chef Partner Engineering']
  spec.email         = ['partnereng@chef.io']

  spec.summary       = 'Client gem for interacting with the Oracle Cloud API.'
  spec.homepage      = 'https://github.com/chef-partners/oracle-cloud-client'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'rest-client', '~> 1.8'
  spec.add_dependency 'ffi-yajl',    '~> 2.2'

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry'
end
