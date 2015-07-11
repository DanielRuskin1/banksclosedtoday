# As cache_classes is false in development, we need to manually eagerload all classes.
# Otherwise, code that depends on subclasses (e.g. Country#supported_countries) will not work as normal.
if Rails.env.development?
  Rails.application.eager_load!
end