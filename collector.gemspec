# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "collector/version"

Gem::Specification.new do |spec|
  spec.name          = "collector"
  spec.version       = Collector::VERSION
  spec.authors       = ["Isaac Williams", "Adam Williams"]
  spec.email         = ["developer@thewilliams.ws"]

  spec.summary       = %q{A CLI for collecting resources.}
  spec.homepage      = "https://github.com/wfth/collector"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = ""
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"

  spec.add_dependency "beachball"
  spec.add_dependency "pg", "~> 0.20.0"
  spec.add_dependency "aws-sdk", "~> 2.8.9"
  spec.add_dependency "mechanize", "~> 2.7.5"
  spec.add_dependency "thor", "~> 0.19.4"
end
