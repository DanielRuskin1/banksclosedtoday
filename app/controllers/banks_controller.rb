class BanksController < ApplicationController
  def index
    # Default country should be the user's country param
    country_code = params[:country].upcase if params[:country].is_a?(String)

    # If a country param was not passed in, query for one based on the IP
    unless country_code.present?
      # Query
      country_response = UserCountryService.country_for_ip(request.remote_ip)

      # If successful, set to param.
      # Otherwise, set error.
      if country_response.success
        country_code = country_response.country_code
      else
        @error = :no_country
      end
    end

    # Check if the country is supported:
    # 1. Get get the appropriate info if so
    # 2. Set an error if not.
    # Skip this part if an error was already set above
    unless @error
      if BankService::SUPPORTED_COUNTRIES.include?(country_code)
        # Get the appropriate BankService
        bank_service = BankService.get_service_for_country(country_code)

        # Get the bank's status
        @bank_status = bank_service.bank_status
        @bank_schedule = bank_service.bank_schedule
      else
        @error = :unsupported_country
      end
    end
  end
end
