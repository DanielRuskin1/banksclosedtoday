# If Keen is defined, start EventMachine - this will ensure that Keen#publish_async requests work as normal.
if defined?(Keen)
  require 'em-http-request'
  Thread.new { EventMachine.run }
end