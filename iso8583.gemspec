# frozen_string_literal: true

require_relative "lib/iso8583/version"

Gem::Specification.new do |spec|
  spec.name = "iso8583"
  spec.version = Iso8583::VERSION
  spec.authors = ["Nguyen Tien Dzung"]
  spec.email = ["dzung.nguyentien@every-pay.com"]

  spec.summary = "Modern Ruby implementation of ISO 8583 financial messaging protocol"
  spec.description = "A clean, well-tested Ruby library for parsing, building, and validating ISO 8583 financial messages with support for various encoding formats (ASCII, BCD, Binary)"
  spec.homepage = "https://github.com/nguyentiendzung/iso8583"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/nguyentiendzung/iso8583"
  spec.metadata["changelog_uri"] = "https://github.com/nguyentiendzung/iso8583/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
