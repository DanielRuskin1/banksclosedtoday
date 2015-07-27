# UserLocationService is used to perform GEOIP lookups on users.  This allows us to serve country-specific messaging.
class UserLocationService
  # UserCountryService exception classes
  class UserLocationServiceError < StandardError; end
  class UnknownResponseFormatError < UserLocationServiceError; end # GEOIP response data is in an unknown format
  class UnknownResponseError < UserLocationServiceError; end # An unknown error was sent back by the GEOIP service
  class UnknownIpError < UserLocationServiceError; end # The GEOIP service cannot lookup the provided IP address

  # Service to use for GEOIP lookups
  GEOIP_SERVICE_URL = 'https://geoip.maxmind.com/geoip/v2.1/city'

  # GEOIP credentials
  GEOIP_USERNAME = ENV.fetch('GEOIP_USERNAME')
  GEOIP_PASSWORD = ENV.fetch('GEOIP_PASSWORD')

  ###
  # Error codes specified in this list represent an IP address that the GEOIP service cannot lookup.
  # These will generate a UnknownIpError.
  UNSUPPORTED_IP_ADDRESS_ERROR_CODES = [
    'IP_ADDRESS_RESERVED', # Reserved/private IP range
    'IP_ADDRESS_NOT_FOUND', # No country data available for IP
  ]

  ###
  # Exceptions on this list can be considered expected.
  # All exceptions in the location_for_request method are rescued -
  # but exceptions listed here will not trigger a Rollbar notification.
  EXPECTED_EXCEPTIONS = [
    UnknownIpError # No country code was found by the GEOIP service
  ]

  ###
  # Calls the GEOIP_SERVICE_URL and returns a CountryStatusResponse.
  # Error types specified in REQUEST_EXCEPTIONS_TO_RESCUE will be rescued, and a blank UserLocation will be returned.
  # Other error types will be raised.
  def self.location_for_request(request)
    # Get country_code for the IP
    country_code = send_request_with_remote_ip(request.remote_ip)

    # Track with Keen
    KeenService.track_action(:country_lookup_success,
                             request: request,
                             tracking_params: { country_code: country_code })

    # Return a UserLocation object with the country_code
    UserLocationServiceResponse.new(success: true, country_code: country_code)
  rescue => exception
    # Track with Keen
    KeenService.track_action(:country_lookup_failed,
                             request: request,
                             tracking_params: { country_code: country_code, error: exception.class.to_s })

    # Notify Rollbar if the error type is not included in
    # EXPECTED_EXCEPTIONS
    unless EXPECTED_EXCEPTIONS.any? { |type| exception.is_a?(type) }
      Rollbar.error(exception)
    end

    # Return a blank UserLocation object
    UserLocationServiceResponse.new(success: false)
  end

  ###
  # Helper method to send a GEOIP lookup request with the given remote IP
  # This method should not be used directly; the above location_for_request method should be used instead.
  # The location_for_request method includes logging and error handling logic.
  REQUEST_TIMEOUT = 2.seconds # Actual timeout ends up being twice this (read timeout + open timeout)
  def self.send_request_with_remote_ip(remote_ip)
    # Run request and get response
    response = faraday_connection.get do |req|
      req.url "#{remote_ip}" # Base path + IP address
      req.headers['Accept'] = 'application/json' # JSON format
      req.options.timeout = REQUEST_TIMEOUT # Read timeout
      req.options.open_timeout = REQUEST_TIMEOUT # Open timeout
    end

    # If the response returned a 200, get the country_code.
    # Otherwise, handle the error.
    if response.status == 200
      get_country_code_from_response(response)
    else
      handle_response_error(response)
    end
  end

  # Helper method that returns a Faraday connection to the GEOIP service
  def self.faraday_connection
    @conn ||= Faraday.new(url: GEOIP_SERVICE_URL) do |conn|
      conn.basic_auth GEOIP_USERNAME, GEOIP_PASSWORD # Request authentication
      conn.use Faraday::Adapter::NetHttp
    end
  end

  ###
  # Helper method to take in a successful Faraday response, then return the included country_code.
  # If no country_code can be found, a UnknownResponseFormatError will be raised.
  def self.get_country_code_from_response(response)
    # Parse JSON into Hash
    parsed_json = JSON.parse!(response.body)

    # Get country element; fail if not present
    country_element = parsed_json['country']
    raise_error_with_response(UnknownResponseFormatError, response) unless country_element

    # Get iso_code; fail if not present
    country_code = country_element['iso_code']
    raise_error_with_response(UnknownResponseFormatError, response) unless country_code

    # Return obtained country_code
    country_code
  rescue JSON::ParserError
    # The response data was not valid JSON
    raise_error_with_response(UnknownResponseFormatError, response)
  end

  ###
  # Helper method to take in a failed Faraday response, then figure out what went wrong.
  # UserLocationServiceErrors will be raised.
  def self.handle_response_error(response)
    if [400, 404].include?(response.status)
      # Try parsing the JSON
      parsed_json = JSON.parse!(response.body)

      # If the code represents an unsupported IP,
      # raise a UnknownIpError.
      raise_error_with_response(UnknownIpError, response) if UNSUPPORTED_IP_ADDRESS_ERROR_CODES.include?(parsed_json['code'])
    end

    # If no raise occurred above, we weren't able to identify any known error cases.
    # Raise a default UnknownResponseError.
    raise_error_with_response(UnknownResponseError, response)
  rescue JSON::ParserError
    # The response data was not valid JSON
    raise_error_with_response(UnknownResponseFormatError, response)
  end

  ###
  # Helper method to raise the provided error class
  # with the provided Faraday response as the message.
  def self.raise_error_with_response(error_class, response)
    fail error_class, "#{response.status}: #{response.body}"
  end

  # Wrapper for UserLocationService responses.
  class UserLocationServiceResponse
    attr_accessor :success, :country_code

    def initialize(options = {})
      @success = options[:success]
      @country_code = options[:country_code]
    end
  end
end
