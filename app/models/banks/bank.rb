class Bank
  # Generic "the weekend" closure reason
  THE_WEEKEND_CLOSURE_MESSAGE = 'the weekend'

  # Base exception class for BankService errors
  class BankError < StandardError; end

  ###
  # Name of the schedule used to determine bank statuses
  # This must be implemented in subclasses.
  def self.schedule_name
    fail NotImplementedError
  end

  ###
  # Link to the schedule used to determine bank statuses
  # This must be implemented in subclasses.
  def self.schedule_link
    fail NotImplementedError
  end

  ###
  # The time to use them determining the bank status, taking into account the correct time zone.
  # This must be implemented in subclasses.
  def self.time_to_check
    fail NotImplementedError
  end

  ###
  # Method that returns a reason for bank closure.
  # If this is nil, banks are not closed.
  # This must be implemented in subclasses.
  def self.bank_closure_reason
    fail NotImplementedError
  end
end
