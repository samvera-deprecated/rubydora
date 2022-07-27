source "https://rubygems.org"

if ENV['ACTIVEMODEL_VERSION']
  gem 'activemodel', ENV['ACTIVEMODEL_VERSION']
end
gemspec

gem 'jruby-openssl', :platform => :jruby

if ENV['RAILS_VERSION']
  if ENV['RAILS_VERSION'] == 'edge'
    gem 'rails', github: 'rails/rails'
    ENV['ENGINE_CART_RAILS_OPTIONS'] = '--edge --skip-turbolinks'
  else
    gem 'rails', ENV['RAILS_VERSION']
  end
end

case ENV['RAILS_VERSION']
when /^5.2/
  gem 'bundler', '~> 2.0'
end
