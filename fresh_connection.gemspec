# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fresh_connection/version'

Gem::Specification.new do |spec|
  spec.name          = "fresh_connection"
  spec.version       = FreshConnection::VERSION
  spec.authors       = ["Tsukasa OISHI"]
  spec.email         = ["tsukasa.oishi@gmail.com"]

  spec.summary       = %q{FreshConnection supports connections with configured replica servers.}
  spec.description   = %q{https://github.com/tsukasaoishi/fresh_connection}
  spec.homepage      = "https://github.com/tsukasaoishi/fresh_connection"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.1'

  spec.add_dependency 'activerecord', '>= 4.2.0', '< 5.1'
  spec.add_dependency 'activesupport', '>= 4.2.0', '< 5.1'
  spec.add_dependency 'concurrent-ruby', '~> 1.0.0'

  spec.add_development_dependency 'mysql2', '>= 0.3.13', '< 0.5'
  spec.add_development_dependency 'pg', '~> 0.11'
  spec.add_development_dependency "bundler", ">= 1.3.0", "< 2.0"
  spec.add_development_dependency "rake", ">= 0.8.7"
  spec.add_development_dependency 'appraisal'
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "benchmark-ips"
  #spec.add_development_dependency "pry-byebug"  # debugging only
end
