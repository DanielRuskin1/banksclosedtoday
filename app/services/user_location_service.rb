# UserLocationService is used to perform GEOIP lookups on users.  This allows us to serve country-specific messaging.
class UserLocationService
  # Service to use for GEOIP lookups
  GEOIP_SERVICE_URL = 'http://api.hostip.info'

  # Country code that, if received by the HostIP.info service, indicates a malformed request
  HOSTIP_INVALID_COUNTRY_CODE = 'XX'

  # Base exception class for UserCountryService errors
  class UserLocationServiceError < StandardError; end
  class UnknownResponseFormat < UserLocationServiceError; end # Exception for GEOIP response data that is in an unknown format
  class NoRemoteIpError < UserLocationServiceError; end # Exception for a blank remote_ip
  class ReceivedBadCountryError < UserLocationServiceError; end # Exception for an invalid country from the GEOIP service (HOSTIP_INVALID_COUNTRY_CODE)

  ###
  # Expected errors to rescue in the country method
  # If any of these error types occur, the following actions will be taken:
  # 1. Keen will be notified for tracking purposes
  # 2. The error will be "hidden" - a blank UserLocation will be returned
  # Other error types will not be rescued.
  EXCEPTIONS_TO_RESCUE = [
    Faraday::TimeoutError, # Request timed out
    Faraday::ConnectionFailed, # Connection failed (e.g. due to the server being down)
    Faraday::ClientError, # Request failed (e.g. due to 500 error)
    NoRemoteIpError, # remote_ip is nil - this could occur if the method is called for a malformed request in BanksController
    ReceivedBadCountryError # Bad country returned by GEOIP service,
  ]

  ###
  # Errors that are expected to occur, but that should still result in a Rollbar notifications.
  # These exceptions will still be rescued, and the error will be "hidden" to the caller (with a blank UserLocation).
  EXCEPTIONS_TO_RESCUE_AND_NOTIFY = [
    UnknownResponseFormat # GEOIP response data is in an unknown format
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
  rescue *(EXCEPTIONS_TO_RESCUE + EXCEPTIONS_TO_RESCUE_AND_NOTIFY) => e
    # Track with Keen
    KeenService.track_action(:country_lookup_failed,
                             request: request,
                             tracking_params: { country_code: country_code, error: e.class.to_s, error_message: e.message })

    # Notify Rollbar if necessary
    Rollbar.error(e) if EXCEPTIONS_TO_RESCUE_AND_NOTIFY.include?(e.class)

    # Return a blank UserLocation object
    UserLocation.new
  end

  # Helper method to send a GEOIP lookup request with the given remote IP
  REQUEST_TIMEOUT = 1.second # Timeout requests in 1 second
  def self.send_request_with_remote_ip(remote_ip)
    # Run request and get result
    request_result = faraday_connection.get do |req|
      req.url '/' # Base path
      req.params[:ip] = remote_ip # IP to search for
      req.options.timeout = REQUEST_TIMEOUT # Read timeout
      req.options.open_timeout = REQUEST_TIMEOUT # Open timeout
    end.body

    # Get country_code
    country_code = get_country_code_from_xml(request_result)

    # If the request was successful, return the result.
    # Otherwise, raise an exception.
    if country_code == HOSTIP_INVALID_COUNTRY_CODE
      fail ReceivedBadCountryError, country_code
    else
      country_code
    end
  end

  # Helper method that returns a Faraday connection to the GEOIP service
  def self.faraday_connection
    @conn ||= Faraday.new(url: GEOIP_SERVICE_URL) do |conn|
      conn.use Faraday::Response::RaiseError # Raise an exception for 40x/50x responses
      conn.use Faraday::Adapter::NetHttp
    end
  end

  ###
  # Helper method to take in HostIP XML data, then return the included country_code.
  # If no country_code can be found, a UnknownDataFormat error will be raised.
  def self.get_country_code_from_xml(xml_data)
    # Parse XML into Hash
    parsed_xml = Hash.from_xml(xml_data)

    # Get result set element
    result_set = parsed_xml['HostipLookupResultSet']
    fail UnknownResponseFormat, xml_data unless result_set

    # Get feature member element
    feature_member = result_set.try(:[], 'featureMember')
    fail UnknownResponseFormat, xml_data unless feature_member

    # Get host IP result element
    host_ip_result_element = feature_member.try(:[], 'Hostip')
    fail UnknownResponseFormat, xml_data unless host_ip_result_element

    # Get country abbreviation
    country_code = host_ip_result_element.try(:[], 'countryAbbrev')
    fail UnknownResponseFormat, xml_data unless country_code

    # Return obtained result
    country_code
  rescue REXML::ParseException
    # The response data was not in XML
    raise UnknownResponseFormat, xml_data
  end
end
