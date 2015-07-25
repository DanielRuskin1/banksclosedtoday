def stub_geoip_lookup(country_code)
  # Get HostIP sample response, and add the country_code
  file_name = File.join(File.dirname(__FILE__), '../fixtures/geoip_lookup/geoip_response.json')
  response_body = File.read(file_name) % country_code

  # Stub request with body
  stub_request(:get, /https:\/\/GEOIP_USERNAME:GEOIP_PASSWORD@geoip.maxmind.com\/geoip\/v2.1\/city/)
    .to_return(status: 200, body: response_body, headers: {})

  # Return expected body
  response_body
end

def stub_server_error_geoip_lookup
  stub_request(:get, /https:\/\/GEOIP_USERNAME:GEOIP_PASSWORD@geoip.maxmind.com\/geoip\/v2.1\/city/)
    .to_return(status: 500, body: 'Weird Error Message', headers: {})
end

def stub_request_failed_geoip_lookup(type)
  # Figure out what response code to use
  response_code = case type
                  when "ip_reserved", "unknown_lookup_error", "invalid_lookup_error_json"
                    400
                  when "ip_not_found"
                    404
                  when "invalid_json", "no_country_element", "no_iso_code"
                    200
                  else
                    raise "Unknown type #{type}!"
                  end

  # Get the response_body to use
  file_name = File.join(File.dirname(__FILE__), "../fixtures/geoip_lookup/#{type}_geoip_response.json")
  response_body = File.read(file_name)

  # Stub request
  stub_request(:get, /https:\/\/GEOIP_USERNAME:GEOIP_PASSWORD@geoip.maxmind.com\/geoip\/v2.1\/city/)
    .to_return(status: response_code, body: response_body, headers: {})

  # Return expected body
  response_body
end

def stub_slow_geoip_lookup
  stub_request(:get, /https:\/\/GEOIP_USERNAME:GEOIP_PASSWORD@geoip.maxmind.com\/geoip\/v2.1\/city/).to_timeout
end

def expect_country_lookup_success_keen_call(country_code: 'US')
  params = {
    request: instance_of(ActionDispatch::Request),
    tracking_params: { country_code: country_code }
  }

  expect_keen_call(:country_lookup_success, params)
end

def expect_country_lookup_failed_keen_call(error_class, country_code: nil)
  params = {
    request: instance_of(ActionDispatch::Request),
    tracking_params: { country_code: country_code, error: error_class.to_s }
  }

  expect_keen_call(:country_lookup_failed, params)
end

def expect_no_geoip_requests
  expect(UserLocationService).to_not have_received(:location_for_request)
end

def expect_one_geoip_request
  expect(UserLocationService).to have_received(:location_for_request).once
end
