# Class to represent a user's location.
# Country objects are only used for supported locations,
# but UserLocations can also represent unsupported locations
# (e.g. if a user visits the site from an unsupported country).
class UserLocation
  attr_accessor :country_code

  def initialize(options = {})
    @country_code = options[:country_code]
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
