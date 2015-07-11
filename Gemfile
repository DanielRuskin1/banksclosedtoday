source 'https://rubygems.org'

# Rails
gem 'rails', '3.2.21'

# Exception monitoring
gem 'rollbar', '1.5.3'

# Used for holiday detection in BankService#bank_status
gem 'holidays', '2.2.0'

# NewRelic site monitoring
gem 'newrelic_rpm', '3.12.1.298'

group :production do
  # Metrics/analytics
  gem 'keen', '0.9.2'

  # Used for async Keen publishing
  gem "em-http-request", "~> 1.0"
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  # Asset compiliation
  gem 'sass-rails'

  # JQuery
  gem 'jquery-rails'

  # Coffeescript
  gem 'coffee-rails'

  # JS uglifier/minimizer
  gem 'uglifier'
end

group :development, :test do
  # Time management lib
  gem 'timecop'

  # Ruby style enforcement
  gem 'rubocop'
end

group :test do
  # Testing library
  gem 'rspec-rails'

  # Feature test libraries
  gem 'poltergeist'
  gem 'capybara'

  # Test mocking library
  gem 'webmock'
end
