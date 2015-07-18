# Controller for checking bank statuses; only index is implemented at the moment
class BanksController < ApplicationController
  def index
    # If the user passed in a country_code, get a UserLocation based on the provided param
    # Otherwise, get one based on their IP address.
    if params[:country_code].is_a?(String)
      user_location = UserLocation.new(country_code: params[:country_code].upcase)
    else
      user_location = UserLocationService.location_for_request(request)
    end

    # Get the UserLocation's Country
    @country = user_location.country

    # If a Country was found, get the Bank closure reason.
    if @country
      @bank_closure_reason = @country.bank.bank_closure_reason
    else
      # If a Country was not found, two errors could have occurred:
      # 1. We could have not found the user's country (country_code is blank), or
      # 2. The user's country is not supported (country_code is not blank - but no Country was found)
      @error = user_location.country_code.blank? ? :no_country : :unsupported_country
    end

    # Track with Keen
    KeenService.track_action(:bank_status_check,
                             request: request,
                             tracking_params: { country_code: user_location.country_code, error: @error })
  end
end
