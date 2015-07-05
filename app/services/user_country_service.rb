class UserCountryService
  # Service to use for GEOIP lookups
  GEOIP_SERVICE_URL = "http://api.hostip.info/country.php?ip=%s"

  # Country code that, if received by the HostIP.info service, indicates a malformed request
  HOSTIP_INVALID_COUNTRY_CODE = "XX"

  # Base exception class for UserCountryService errors
  class UserCountryServiceError < StandardError; end

  # Exception for a blank remote_ip
  class NoRemoteIpError < UserCountryServiceError; end

  # Exception for an invalid country from the GEOIP service (HOSTIP_INVALID_COUNTRY_CODE)
  class ReceivedBadCountryError < UserCountryServiceError; end

  ###
  # "Expected" errors to rescue in the country method
  # If any of these error types occur, an unsuccessful response will be returned.
  # Other error types will not be rescued.
  EXPECTED_ERRORS_TO_RESCUE = [
    URI::InvalidURIError, # Malformed IP or URI
    Timeout::Error, # Request took too long
    Errno::EINVAL, # Net:HTTP error
    Errno::ECONNRESET, # Net:HTTP error
    EOFError, # Net:HTTP error
    Net::HTTPBadResponse, # Net:HTTP error
    Net::HTTPHeaderSyntaxError, # Net:HTTP error
    Net::ProtocolError, # Net:HTTP error
    NoRemoteIpError, # remote_ip is nil - this could occur if the method is called for a malformed request in BanksController
    ReceivedBadCountryError # Bad country returned by GEOIP service,
  ]

  ###
  # Calls the GEOIP_SERVICE_URL and returns a CountryStatusResponse.
  # Error types specified in EXPECTED_ERRORS_TO_RESCUE will be caught, and an unsuccessful CountryStatusResponse will be returned.
  # Other error types will be raised.
  def self.country_for_ip(remote_ip)
    # remote_ip cannot be blank
    raise NoRemoteIpError unless remote_ip.present?

    # Generate URL
    uri_to_request = URI.parse(GEOIP_SERVICE_URL % remote_ip)

    # Run request
    country = Timeout::timeout(5) do
      Net::HTTP.get_response(uri_to_request).body
    end

    # Raise here if the returned country code indicates a malformed reuest
    raise ReceivedBadCountryError if country == HOSTIP_INVALID_COUNTRY_CODE

    # Return country
    CountryStatusResponse.new(success: true, country: country)
  rescue *EXPECTED_ERRORS_TO_RESCUE => e
    # Notify Rollbar for tracking purposes
    Rollbar.error(e)

    # Return an unsuccessful response
    CountryStatusResponse.new(success: false)
  end

  class CountryStatusResponse
    attr_accessor :success, :country

    def initialize(options = {})
      @success = options[:success]
      @country = options[:country]
    end
  end
end
