# -*- encoding: utf-8 -*-
# stub: jsonapi-serializers 1.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "jsonapi-serializers".freeze
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mike Fotinakis".freeze]
  s.date = "2018-06-10"
  s.description = "Pure Ruby readonly serializers for the JSON:API spec.".freeze
  s.email = ["mike@fotinakis.com".freeze]
  s.homepage = "https://github.com/fotinakis/jsonapi-serializers".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.7.8".freeze
  s.summary = "Pure Ruby readonly serializers for the JSON:API spec.".freeze

  s.installed_by_version = "2.7.8" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>.freeze, [">= 0"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.2"])
      s.add_development_dependency(%q<factory_girl>.freeze, ["~> 4.5"])
      s.add_development_dependency(%q<activemodel>.freeze, ["~> 4.2"])
    else
      s.add_dependency(%q<activesupport>.freeze, [">= 0"])
      s.add_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.2"])
      s.add_dependency(%q<factory_girl>.freeze, ["~> 4.5"])
      s.add_dependency(%q<activemodel>.freeze, ["~> 4.2"])
    end
  else
    s.add_dependency(%q<activesupport>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.2"])
    s.add_dependency(%q<factory_girl>.freeze, ["~> 4.5"])
    s.add_dependency(%q<activemodel>.freeze, ["~> 4.2"])
  end
end
