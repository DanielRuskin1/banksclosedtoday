class BankService
  HOLIDAYS_TO_OBSERVE = [
    "New Year's Day",
    'Martin Luther King, Jr. Day',
    "Presidents' Day",
    'Memorial Day',
    'Independence Day',
    'Labor Day',
    'Columbus Day',
    'Veterans Day',
    'Thanksgiving',
    'Christmas Day',
    'Inauguration Day'
  ]

  BANKS_ARE_OPEN_MESSAGE = 'Most banks are open today.'
  WEEKEND_ERROR_MESSAGE = 'Most banks are closed as today is not a weekday.'

  def self.bank_status(time_to_check)
    # If today falls on a weekend, return an error
    if time_to_check.saturday? || time_to_check.sunday?
      return BankStatusResponse.new(closed: true, message: WEEKEND_ERROR_MESSAGE)
    end

    # Get any holiday names today
    holidays_today = get_applicable_holiday_names_for_day(time_to_check)

    # If today is Friday, get any Saturday holiday names.
    # Otherwise, if today is Sunday, get any Monday holiday names.
    if time_to_check.friday?
      holidays_today += get_applicable_holiday_names_for_day(time_to_check + 1.day)
    elsif time_to_check.monday?
      holidays_today += get_applicable_holiday_names_for_day(time_to_check - 1.day)
    end

    # If any applicable holidays exist today, banks are closed.
    if (holidays_today & HOLIDAYS_TO_OBSERVE).any?
      return BankStatusResponse.new(closed: true, message: message_for_holidays(holidays_today))
    end

    # It's safe to assume that banks are open at this point
    # Return a response to that effect
    BankStatusResponse.new(closed: false, message: BANKS_ARE_OPEN_MESSAGE)
  end

  def self.get_applicable_holiday_names_for_day(day)
    day.holidays(:us, :us_dc).map { |holiday| holiday[:name] }.compact.uniq
  end

  def self.message_for_holidays(holiday_names)
    # Get pluralized holiday word
    holiday_word = 'holiday'.pluralize(holiday_names.count)

    # Create message
    "Most banks are closed today due to the following #{holiday_word}: #{holiday_names.to_sentence}."
  end

  class BankStatusResponse
    attr_accessor :closed, :message

    def initialize(options = {})
      @closed = options[:closed]
      @message = options[:message]
    end
  end
end
