# Represents a Bank in a given country; currently used to store information on Banks (e.g. scheduling logic).
class Bank
  # Generic "the weekend" closure reason
  THE_WEEKEND_CLOSURE_MESSAGE = 'the weekend'

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
  # The Holiday regions that this bank observes.
  # This must be implemented in subclasses.
  def self.applicable_holiday_regions
    fail NotImplementedError
  end

  ###
  # The list of holidays that this bank observes.
  # This must be implemented in subclasses.
  def self.observed_holidays
    fail NotImplementedError
  end

  ###
  # Helper method that returns a list of applicable holidays for the provided day.
  # The applicable_holiday_regions and observed_holidays for the region are taken into account.
  def self.get_applicable_holiday_names_for_day(day)
    day.holidays(applicable_holiday_regions).map do |holiday|
      # Include the holiday's name, but only if it's an observed holiday.
      holiday[:name] if observed_holidays.include?(holiday[:name])
    end.compact.uniq
  end

  ###
  # Method that returns a reason for bank closure.
  # If this is nil, banks are not closed.
  # This must be implemented in subclasses.
  def self.bank_closure_reason
    fail NotImplementedError
  end
end
