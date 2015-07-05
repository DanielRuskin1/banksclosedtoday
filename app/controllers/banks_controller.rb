class BanksController < ApplicationController
  def index
    # Default country should be the user's country param
    @country = params[:country]

    # If a country param was not passed in, query for one based on the IP
    if !@country
      # Query
      country_response = UserCountryService.country_for_ip(request.remote_ip)

      # If successful, set to param.
      # Otherwise, set error.
      if country_response.success
        @country = country_response.country
      else
        @error = :no_country
      end
    end

    # Check if the country is supported:
    # 1. Get the bank_status if so,
    # 2. Set an error if not.
    # Skip this part if an error was already set above
    if !@error
      if BankService::SUPPORTED_COUNTRIES.include?(@country)
        @bank_status = BankService.get_service_for_country(@country).bank_status
      else
        @error = :unsupported_country
      end
    end
  end
end
