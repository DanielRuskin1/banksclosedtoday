class BankService
  SUPPORTED_COUNTRIES = {
    "US" => "United States",
  }

  BANKS_ARE_OPEN_MESSAGE = 'Most banks are open today.'
  WEEKEND_ERROR_MESSAGE = 'Most banks are closed as today is not a weekday.'

  # Base exception class for BankService errors
  class BankServiceError < StandardError; end

  # Unsupported country passed (e.g. to the get_service_for_country method)
  class UnsupportedCountryError < BankServiceError; end

  ###
  # Method to get the correct BankService for a given country.
  # The supported countries here should mirror the SUPPORTED_COUNTRIES constant.
  def self.get_service_for_country(country)
    case country
    when "US"
      UsBankService
    else
      raise UnsupportedCountryError
    end
  end

  ###
  # The time to use them determining the bank status, taking into account the correct time zone.
  # This is only implemented in subclasses.
  def self.time_to_check
    raise NotImplementedError
  end

  ###
  # Method to get the current bank's status; returns a BankStatusResponse.
  # This is only implemented in subclasses.
  def self.bank_status
    raise NotImplementedError
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
