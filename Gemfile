source 'https://rubygems.org'
ruby '2.1.6'

# Rails
gem 'rails', '3.2.21'

# Thin webserver (faster than default WEBrick)
gem 'thin', '1.6.3'

# Exception monitoring
gem 'rollbar', '2.1.1'

# Used for holiday detection in Bank#get_applicable_holiday_names_for_day
gem 'holidays', '2.2.0'

# NewRelic site monitoring
gem 'newrelic_rpm', '3.12.1.298'

# Logging
gem 'scrolls', '0.3.8'

# Web requests (see UserLocationService)
gem 'faraday', '0.9.1'

group :production do
  # Metrics/analytics
  gem 'keen', '0.9.2'

  # Async event processing
  gem 'em-http-request', '1.1.2'

  # Necessary for asset serving and logging on Heroku
  gem 'rails_12factor', '0.0.3'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  # Asset compiliation
  gem 'sass-rails', '3.2.6'

  # JQuery
  gem 'jquery-rails', '3.1.3'

  # Coffeescript
  gem 'coffee-rails', '3.2.2'

  # JS uglifier/minimizer
  gem 'uglifier', '2.7.1'
end

group :development, :test do
  # Time management lib
  gem 'timecop', '0.7.4'

  # Ruby style enforcement
  gem 'rubocop', '0.32.1'

  # Default dev/test env variables
  gem 'dotenv-rails', '2.0.1'

  # Colorized output (e.g. for deploy logging)
  gem 'colorize', '0.7.7'
end

group :test do
  # Testing library
  gem 'rspec-rails', '3.3.2'

  # Test mocking library
  gem 'webmock', '1.21.0'

  # Feature test libraries
  gem 'poltergeist', '1.6.0'
  gem 'capybara', '2.4.4'

  # Code coverage gem
  gem 'simplecov', '0.8.2'
end
