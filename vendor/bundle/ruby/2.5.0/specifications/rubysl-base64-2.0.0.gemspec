# -*- encoding: utf-8 -*-
# stub: rubysl-base64 2.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rubysl-base64".freeze
  s.version = "2.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Brian Shirai".freeze]
  s.date = "2013-09-01"
  s.description = "Ruby standard library base64.".freeze
  s.email = ["brixen@gmail.com".freeze]
  s.homepage = "https://github.com/rubysl/rubysl-base64".freeze
  s.licenses = ["BSD".freeze]
  s.rubygems_version = "2.7.8".freeze
  s.summary = "Ruby standard library base64.".freeze

  s.installed_by_version = "2.7.8" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_development_dependency(%q<mspec>.freeze, ["~> 1.5"])
    else
      s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_dependency(%q<mspec>.freeze, ["~> 1.5"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_dependency(%q<mspec>.freeze, ["~> 1.5"])
  end
end
