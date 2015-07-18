# Class for supported country data; country-specific information stored in subclasses
class Country
  # Base exception class for Country errors
  class CountryError < StandardError; end
  class NoCountryError < CountryError; end # No Country class exists for the provided code

  # Returns a Country class for the provided code.
  def self.country_for_code(country_code)
    # Look for a descendant with the country code,
    # and return if one is found
    descendants.each do |descendant|
      return descendant if country_code == descendant.code
    end

    # If no return occurred above,
    # the country is not supported.
    fail NoCountryError
  end

  ###
  # Looks through all Country descendants, then
  # returns a hash of:
  # Keys: Country codes
  # Values: Country names
  def self.supported_countries
    # Init hash of supported countries
    supported_countries = {}

    # Add key/values for each descendant
    descendants.each do |descendant|
      supported_countries[descendant.code] = descendant.name
    end

    # Return hash
    supported_countries
  end

  # Code of this country
  # Must be implemented in subclasses.
  def self.code
    fail NotImplementedError
  end

  # Name of this country
  # Must be implemented in subclasses.
  def self.name
    fail NotImplementedError
  end

  # Bank for this country
  # Must be implemented in subclasses.
  def self.bank
    fail NotImplementedError
  end
end
