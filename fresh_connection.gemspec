# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{fresh_connection}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Tsukasa OISHI"]
  s.date = %q{2010-10-16}
  s.description = %q{MiyazakiResistance is a library like ActiveRecord to use Tokyo Tyrant.}
  s.email = ["tsukasa.oishi@gmail.com"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README"]
  s.files = %w|
    Rakefile
    fresh_connection.gemspec
    lib/fresh_connection.rb
    lib/fresh_connection/slave_connection.rb
    lib/fresh_connection/rack/connection_management.rb
    rails/initializers/active_record_base.rb
  |
  s.has_rdoc = true
  s.homepage = %q{http://www.kaeruspoon.net/keywords/MiyazakiResistance}
  s.post_install_message = %q{PostInstall.txt}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{miyazakiresistance}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{MiyazakiResistance is a library like ActiveRecord to use Tokyo Tyrant.}
end
