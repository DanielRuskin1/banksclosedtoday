# BankService is used to determine whether banks in a given country are open.
class BankService
  SUPPORTED_COUNTRIES = {
    'US' => 'United States'
  }

  SUPPORTED_COUNTRY_BANK_SERVICES = {
    'US' => UsBankService
  }

  # Closure reason constants
  WEEKEND_CLOSURE_REASON = 'the weekend'

  # Base exception class for BankService errors
  class BankServiceError < StandardError; end

  # Unsupported country passed (e.g. to the get_service_for_country method)
  class UnsupportedCountryError < BankServiceError; end

  ###
  # Method to get the correct BankService for a given country.
  # Uses the SUPPORTED_COUNTRIES and SUPPORTED_COUNTRY_BANK_SERVICES constants.
  def self.get_service_for_country(country_code)
    if SUPPORTED_COUNTRIES[country_code]
      SUPPORTED_COUNTRY_BANK_SERVICES[country_code]
    else
      fail UnsupportedCountryError
    end
  end

  # Returns the country for this BankService.
  def self.country_code
    SUPPORTED_COUNTRY_BANK_SERVICES.invert[self]
  end

  ###
  # Method to get the schedule used to determine bank statuses; returns a BankSchedule.
  # This is only implemented in subclasses.
  def self.bank_schedule
    fail NotImplementedError
  end

  ###
  # The time to use them determining the bank status, taking into account the correct time zone.
  # This is only implemented in subclasses.
  def self.time_to_check
    fail NotImplementedError
  end

  ###
  # Method to get the current bank's status; returns a BankStatusResponse.
  # This is only implemented in subclasses.
  def self.bank_status
    fail NotImplementedError
  end

  def self.banks_open_status_message
    "Most #{country_code} banks are open."
  end

  def self.bank_closed_status_message(reason)
    "Most #{country_code} banks are closed because of #{reason}."
  end

  # Response container for the bank_schedule_used method.
  class BankSchedule
    attr_accessor :country_code, :name, :link

    def initialize(options = {})
      @country_code = options[:country_code]
      @name = options[:name]
      @link = options[:link]
    end
  end

  # Response container for the bank_status method.
  class BankStatusResponse
    attr_accessor :closed, :message

    def initialize(options = {})
      @closed = options[:closed]
      @message = options[:message]
    end
  end
end
