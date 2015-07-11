if Rails.env.production?
  require 'em-http-request'
  Thread.new { EventMachine.run }
end