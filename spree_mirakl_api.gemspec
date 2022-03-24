# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_mirakl_api'
  s.version     = '3.2.0'
  s.summary     = 'Spree Wrapper Gem to interact with Mirakl API'
  s.description = 'description'
  s.required_ruby_version = '>= 2.1.0'

  # s.author    = 'You'
  # s.email     = 'you@example.com'
  # s.homepage  = 'http://www.spreecommerce.com'
  s.license = 'BSD-3'

  s.author    = 'Felix Gray'

  # s.files       = `git ls-files`.split("\n").reject { |f| f.match(/^spec/) && !f.match(/^spec\/fixtures/) }
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core'
  s.add_dependency 'httparty'

  s.add_development_dependency 'capybara'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_girl'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'simplecov'
end
