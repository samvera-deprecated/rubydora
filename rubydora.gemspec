# Provide a simple gemspec so you can easily use your enginex
# project in your rails apps through git.
require File.join(File.dirname(__FILE__), 'lib/rubydora/version')
Gem::Specification.new do |s|
  s.name        = 'rubydora'
  s.version     = Rubydora::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Chris Beer']
  s.email       = ['chris@cbeer.info']
  s.summary     = 'Fedora Commons REST API ruby library'
  s.description = 'Fedora Commons REST API ruby library'
  s.homepage    = 'http://github.com/projecthydra/rubydora'
  s.license     = 'Apache-2.0'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
  s.metadata      = { "rubygems_mfa_required" => "true" }

  s.add_dependency 'rest-client'
  s.add_dependency 'nokogiri'
  s.add_dependency 'equivalent-xml'
  s.add_dependency 'mime-types'
  s.add_dependency 'activesupport'
  s.add_dependency 'activemodel', '>= 5.2'
  s.add_dependency 'hooks', '~> 0.3'
  s.add_dependency 'deprecation'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'bundler', '>= 1.0.14'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'jettywrapper', '>= 1.4.0'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'coveralls'
  s.add_development_dependency 'rspec_junit_formatter'
end
