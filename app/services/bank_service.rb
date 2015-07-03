class BankService
  SPECIAL_BANK_HOLIDAYS = [
    { date: DateTime.parse("July 3, 2015"), name: "Independence Day (Observed)" },
    { date: DateTime.parse("November 10, 2017"), name: "Veterans Day (Observed)" },
  ]

  HOLIDAYS_TO_OBSERVE = [
    "New Year's Day",
    "Martin Luther King, Jr. Day",
    "Inauguration Day",
    "Presidents' Day",
    "Memorial Day",
    "Independence Day",
    "Independence Day (Observed)",
    "Labor Day",
    "Columbus Day",
    "Veterans Day",
    "Veterans Day (Observed)",
    "Thanksgiving",
    "Christmas Day",
  ]

  BANKS_ARE_OPEN_MESSAGE = "Banks are open today."
  WEEKEND_ERROR_MESSAGE = "Banks are closed as today is not a weekday."

  def self.bank_status(time_to_check)
    # If today falls on a weekend, return an error
    if time_to_check.saturday? || time_to_check.sunday?
      return BankStatusResponse.new(open: false, message: WEEKEND_ERROR_MESSAGE)
    end

    # Get any holiday names today
    holidays_today = time_to_check.holidays(:us, :us_dc).map { |holiday| holiday[:name] }.compact.uniq
    holidays_today += get_special_bank_holidays(time_to_check) # Merge with special holidays

    # If any applicable holidays exist today, banks are closed.
    if (holidays_today & HOLIDAYS_TO_OBSERVE).any?
      return BankStatusResponse.new(open: false, message: message_for_holidays(holidays_today))
    end

    # It's safe to assume that banks are open at this point
    # Return a response to that effect
    BankStatusResponse.new(open: true, message: BANKS_ARE_OPEN_MESSAGE)
  end

  def self.get_special_bank_holidays(date_time_to_check)
    # Init special bank holiday array
    special_bank_holidays = []

    # Go through each special holiday
    SPECIAL_BANK_HOLIDAYS.each do |special_bank_holiday|
      # Check if the holiday applies today
      applies_today = special_bank_holiday[:date].to_date == date_time_to_check.to_date

      # Add to array if the holiday applies today
      special_bank_holidays.push(special_bank_holiday[:name]) if applies_today
    end

    # Return array
    special_bank_holidays
  end

  def self.message_for_holidays(holiday_names)
    # Get pluralized holiday word
    holiday_word = "holiday".pluralize(holiday_names.count)

    # Create message
    "Banks are closed today due to the following #{holiday_word}: #{holiday_names.to_sentence}."
  end

  class BankStatusResponse
    attr_accessor :open, :message

    def initialize(options = {})
      @open = options[:open]
      @message = options[:message]
    end
  end
end