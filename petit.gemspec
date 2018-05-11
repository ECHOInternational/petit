# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'petit/version'

Gem::Specification.new do |spec|
  spec.name          = 'petit'
  spec.version       = Petit::VERSION
  spec.authors       = ['Nate Flood']
  spec.email         = ['nflood@echonet.org']
  spec.summary       = 'Url Shortener Implemented In Ruby On AWS'
  spec.description   = 'URL shortener service implemented in Sinatra and backed by AWS.'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'aws-sdk', '~> 2'
  spec.add_dependency 'activesupport', '~> 4.2.3'
  spec.add_dependency 'sinatra'
  spec.add_dependency 'json', '~> 2'
  spec.add_dependency 'jsonapi-serializers'
  spec.add_dependency 'rack-parser'
  spec.add_dependency 'unicorn'
  spec.add_dependency 'rake'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'pry'



end
