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

  spec.add_dependency 'activerecord', '>= 5.2.0', '< 6.1'

  spec.add_development_dependency 'mysql2', '>= 0.4.4'
  spec.add_development_dependency 'pg', '>= 0.18', '< 2.0'
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'appraisal'
  spec.add_development_dependency "minitest", "~> 5.10.0"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "benchmark-ips"
end
