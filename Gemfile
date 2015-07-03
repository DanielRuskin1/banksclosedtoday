source 'https://rubygems.org'

gem 'rails', '3.2.21'


# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

group :development, :test do
  gem 'poltergeist', '~> 1.6.0'
  gem 'capybara',    '~> 2.4.4'
  gem 'rspec-rails', '~> 3.1'
  gem 'timecop',     '~> 0.7.1'
end

gem 'jquery-rails'

# Allows for simple holiday detection; used in BankService#bank_status
gem 'holidays', '2.2.0'