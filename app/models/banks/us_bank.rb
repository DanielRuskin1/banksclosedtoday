# Bank for the United States; implements Federal Reserve Bank scheduling
class UsBank < Bank
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

  # US banks observe the us and us_dc holiday regions
  def self.applicable_holiday_regions
    [:us, :us_dc]
  end

  def self.observed_holidays
    ["New Year's Day",
     'Martin Luther King, Jr. Day',
     "Presidents' Day",
     'Memorial Day',
     'Independence Day',
     'Labor Day',
     'Columbus Day',
     'Veterans Day',
     'Thanksgiving',
     'Christmas Day',
     'Inauguration Day']
  end

  def self.bank_closure_reason
    # If today falls on a weekend, just return that here -
    # it's the primary closure reason.
    if time_to_check.saturday? || time_to_check.sunday?
      return THE_WEEKEND_CLOSURE_MESSAGE
    end

    # Get any holiday names today
    holidays_today = get_applicable_holiday_names_for_day(time_to_check)

    # If any holidays are present, return the holidays as a sentence.
    holidays_today.to_sentence if holidays_today.any?
  end

  ###
  # For US banks, the following logic should be used when getting applicable holidays for a given day:
  # 1. Start with all holidays for the day.
  # 2. If the day is a Friday, add all holidays on the following Saturday.
  # 3. If the day is a Monday, add all holidays from the preceding Sunday.
  # This is the logic followed by the Federal Reserve.
  def self.get_applicable_holiday_names_for_day(day)
    # Get list of holidays
    holidays_today = super
    holidays_today += super(day + 1.day) if day.friday?
    holidays_today += super(day - 1.day) if day.monday?

    # Return
    holidays_today
  end
end
