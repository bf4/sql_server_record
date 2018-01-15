# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sql_server_record/version"

Gem::Specification.new do |spec|
  spec.name          = "sql_server_record"
  spec.version       = SqlServerRecord::VERSION
  spec.authors       = ["Benjamin Fleischer"]
  spec.email         = ["github@benjaminfleischer.com"]

  spec.summary       = %q{A SqlServer ActiveRecord base class}
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/bf4/sql_server_record"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 4.2", "<= 5.3"
  spec.add_dependency "tiny_tds", "~> 2.1"
  spec.add_dependency "activerecord-sqlserver-adapter", "~> 4.2"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
