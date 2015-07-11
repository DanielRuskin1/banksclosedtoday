# UserLocationService is used to perform GEOIP lookups on users.  This allows us to serve country-specific messaging.
class UserLocationService
  # Service to use for GEOIP lookups
  GEOIP_SERVICE_URL = 'http://api.hostip.info/country.php?ip=%s'

  # Country code that, if received by the HostIP.info service, indicates a malformed request
  HOSTIP_INVALID_COUNTRY_CODE = 'XX'

  # Base exception class for UserCountryService errors
  class UserLocationServiceError < StandardError; end
  class NoRemoteIpError < UserLocationServiceError; end # Exception for a blank remote_ip
  class ReceivedBadCountryError < UserLocationServiceError; end # Exception for an invalid country from the GEOIP service (HOSTIP_INVALID_COUNTRY_CODE)

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
  def self.location_for_ip(remote_ip)
    # remote_ip cannot be blank
    fail NoRemoteIpError unless remote_ip.present?

    # Generate URL
    uri_to_request = URI.parse(GEOIP_SERVICE_URL % remote_ip)

    # Run request
    country_code = Timeout.timeout(1) do
      Net::HTTP.get_response(uri_to_request).body
    end

    # Raise here if the returned country code indicates a malformed request
    fail ReceivedBadCountryError if country_code == HOSTIP_INVALID_COUNTRY_CODE

    # Return a UserLocation object with the user's country_code
    UserLocation.new(country_code: country_code)
  rescue *EXPECTED_ERRORS_TO_RESCUE => e
    # Notify Rollbar for tracking purposes
    Rollbar.error(e)

    # Return a blank response
    UserLocation.new
  end
end
