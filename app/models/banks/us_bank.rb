class UsBank < Bank
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

  def self.schedule_name
    'Federal Reserve Bank'
  end

  def self.schedule_link
    'http://www.federalreserve.gov/aboutthefed/k8.htm'
  end

  # The Eastern time zone should be used.
  def self.time_to_check
    DateTime.now.in_time_zone('Eastern Time (US & Canada)')
  end

  def self.bank_closure_reason
    # If today falls on a weekend, just return that here -
    # that's the primary closure reason.
    if time_to_check.saturday? || time_to_check.sunday?
      return THE_WEEKEND_CLOSURE_MESSAGE
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

    # If any holidays are present, return the holidays as a sentence.
    holidays_today.to_sentence if holidays_today.any?
  end

  def self.get_applicable_holiday_names_for_day(day)
    day.holidays(:us, :us_dc).map { |holiday| holiday[:name] if HOLIDAYS_TO_OBSERVE.include?(holiday[:name]) }.compact.uniq
  end
end
