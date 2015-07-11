# Require all models on initialization.
# This is to ensure that we can look through object descendants immediately upon load.
# (e.g. Country#country_for_code)
Dir[Rails.root + 'app/models/**/*.rb'].each do |path|
  require path
end
