# Class to represent a user's location.
class UserLocation
  attr_accessor :request, :country_code

  def initialize(options = {})
    # Set the request and country_code
    @request = options[:request]
    @country_code = options[:country_code].try(:upcase) # Ignore case

    # If a request is present, but the country_code is not yet set,
    # perform a GEOIP lookup.
    @country_code ||= UserLocationService.location_for_request(@request).country_code if @request
  end

  ###
  # Calls Country#country_for_code with this User's country code.
  # If available, the Country object will be returned for this user's location.
  def country
    Country.country_for_code(country_code)
  rescue Country::NoCountryError
    # No country class exists for this UserLocation
    nil
  end
end
