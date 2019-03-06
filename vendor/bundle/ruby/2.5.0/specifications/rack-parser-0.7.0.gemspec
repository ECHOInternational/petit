# -*- encoding: utf-8 -*-
# stub: rack-parser 0.7.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rack-parser".freeze
  s.version = "0.7.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Arthur Chiu".freeze]
  s.date = "2016-04-05"
  s.description = "Rack Middleware for parsing post body data for json, xml and various content types".freeze
  s.email = ["mr.arthur.chiu@gmail.com".freeze]
  s.homepage = "https://www.github.com/achiu/rack-parser".freeze
  s.rubyforge_project = "rack-parser".freeze
  s.rubygems_version = "2.7.8".freeze
  s.summary = "Rack Middleware for parsing post body data".freeze

  s.installed_by_version = "2.7.8" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rack>.freeze, [">= 0"])
      s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
      s.add_development_dependency(%q<rack-test>.freeze, [">= 0"])
    else
      s.add_dependency(%q<rack>.freeze, [">= 0"])
      s.add_dependency(%q<minitest>.freeze, [">= 0"])
      s.add_dependency(%q<rack-test>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<rack>.freeze, [">= 0"])
    s.add_dependency(%q<minitest>.freeze, [">= 0"])
    s.add_dependency(%q<rack-test>.freeze, [">= 0"])
  end
end
