require_relative 'lib/fresh_connection/version'

Gem::Specification.new do |spec|
  spec.name          = "fresh_connection"
  spec.version       = FreshConnection::VERSION
  spec.authors       = ["Tsukasa OISHI"]
  spec.email         = ["tsukasa.oishi@gmail.com"]

  spec.summary       = %q{FreshConnection supports connections with configured replica servers.}
  spec.description   = %q{https://github.com/tsukasaoishi/fresh_connection}
  spec.homepage      = "https://github.com/tsukasaoishi/fresh_connection"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.metadata["homepage_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'activerecord', '>= 6.0.0', '< 6.1'

  spec.add_development_dependency 'mysql2', '>= 0.4.4'
  spec.add_development_dependency 'pg', '>= 0.18', '< 2.0'
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'appraisal'
  spec.add_development_dependency "minitest", "~> 5.10.0"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "benchmark-ips"
end
