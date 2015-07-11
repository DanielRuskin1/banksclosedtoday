require 'em-http-request'

namespace :jobs do
  desc "Work task run by Heroku worker dyno"
  task :work => :environment do
    # Start EventMachine loop
    start_event_machine_thread
  end

  def start_event_machine_thread
    Thread.new { EventMachine.run }
  end
end