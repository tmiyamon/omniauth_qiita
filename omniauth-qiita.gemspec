# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'omniauth-qiita/version'

Gem::Specification.new do |spec|
  spec.name          = "omniauth-qiita"
  spec.version       = Omniauth::Qiita::VERSION
  spec.authors       = ["Takuya Miyamoto"]
  spec.email         = ["miyamototakuya@gmail.com"]
  spec.summary       = 'Qiita Oauth2 Strategy for OmniAuth'
  spec.homepage      = "https://github.com/tmiyamon/omniauth-qiita"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'omniauth-oauth2', '~> 1.2'
  spec.add_runtime_dependency 'multi_json', '~> 1.10'
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'rspec', '~> 3.1'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'webmock'
end
