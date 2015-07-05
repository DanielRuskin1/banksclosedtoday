class UsBankService < BankService
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

  # The Eastern time zone should be used.
  def self.time_to_check
    DateTime.now.in_time_zone("Eastern Time (US & Canada)")
  end

  def self.bank_status
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
    # Create message
    "Most banks are closed today for #{holiday_names.to_sentence}."
  end
end
