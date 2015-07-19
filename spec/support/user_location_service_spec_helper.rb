def stub_geoip_lookup(country_code)
  # Get HostIP sample response, and add the country_code
  file_name = File.join(File.dirname(__FILE__), '../fixtures/geoip_lookup/hostip_response.xml')
  response_body = File.read(file_name) % { country_code: country_code }

  # Stub request with body
  stub_request(:get, /api.hostip.info/)
    .to_return(status: 200, body: response_body, headers: {})

  # Return expected body
  response_body
end

def stub_failed_geoip_lookup
  stub_request(:get, /api.hostip.info/)
    .to_return(status: 404, body: '', headers: {})
end

def stub_invalid_format_geoip_lookup(type)
  # Get the response_body to use
  if type == 'invalid_xml'
    response_body = 'BadXML'
  else
    file_name = File.join(File.dirname(__FILE__), "../fixtures/geoip_lookup/#{type}_hostip_response.xml")
    response_body = File.read(file_name)
  end

  # Stub request
  stub_request(:get, /api.hostip.info/)
    .to_return(status: 200, body: response_body, headers: {})

  # Return expected body
  response_body
end

def stub_slow_geoip_lookup
  stub_request(:get, /api.hostip.info/).to_timeout
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
