source 'https://rubygems.org'

# Rails
gem 'rails', '3.2.21'

# Exception monitoring
gem 'rollbar', '~> 1.5.3'

# Used for holiday detection in BankService#bank_status
gem 'holidays', '2.2.0'

# NewRelic site monitoring
gem 'newrelic_rpm', '3.12.1.298'


# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'

  gem 'uglifier'
end

group :development, :test do
  gem 'poltergeist'
  gem 'capybara'
  gem 'rspec-rails'
  gem 'timecop'
  gem 'rubocop'
end
