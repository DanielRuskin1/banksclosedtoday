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
  # Expected errors to rescue in the country method
  # If any of these error types occur, the following actions will be taken:
  # 1. Keen will be notified for tracking purposes
  # 2. The error will be "hidden" - a blank UserLocation will be returned
  # Other error types will not be rescued.
  REQUEST_EXCEPTIONS_TO_RESCUE = [
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
  # Error types specified in REQUEST_EXCEPTIONS_TO_RESCUE will be rescued, and a blank UserLocation will be returned.
  # Other error types will be raised.
  def self.location_for_request(request)
    # Validate parameter
    fail ArgumentError, "Invalid parameter #{request}!" unless request.is_a?(Rack::Request)

    # Get country_code for the IP
    country_code = send_request_with_remote_ip(request.remote_ip)

    # Track with Keen
    KeenService.track_action(:country_lookup_success,
                             request: request,
                             tracking_params: { country_code: country_code })

    # Return a UserLocation object with the country_code
    UserLocation.new(country_code: country_code)
  rescue *REQUEST_EXCEPTIONS_TO_RESCUE => e
    # Track with Keen
    KeenService.track_action(:country_lookup_failed,
                             request: request,
                             tracking_params: { country_code: country_code, error: e.class.to_s })

    # Return a blank UserLocation object
    UserLocation.new
  end

  def self.send_request_with_remote_ip(remote_ip)
    # Generate URI
    uri_to_request = URI.parse(GEOIP_SERVICE_URL % remote_ip)

    # Run request and get result
    country_code = Net::HTTP.get_response(uri_to_request).body

    # If the request was successful, return the result.
    # Otherwise, raise an exception.
    if country_code == HOSTIP_INVALID_COUNTRY_CODE
      fail ReceivedBadCountryError
    else
      country_code
    end
  end
end
