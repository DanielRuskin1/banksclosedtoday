def stub_geoip_lookup(country_code)
  # Get HostIP sample response, and add the country_code
  file_name = File.join(
    File.dirname(__FILE__),
    '../fixtures/geoip_lookup/hostip_response.xml')
  response_body = File.read(file_name) % { country_code: country_code }

  # Stub request with body
  stub_request(:get, /api.hostip.info/)
    .to_return(status: 200, body: response_body, headers: {})
end

def stub_failed_geoip_lookup
  stub_request(:get, /api.hostip.info/)
    .to_return(status: 500, body: '', headers: {})
end

def stub_geoip_lookup_with_invalid_xml
  stub_request(:get, /api.hostip.info/)
    .to_return(status: 200, body: 'BadXML', headers: {})
end

def stub_geoip_lookup_with_unexpected_xml
  # Get HostIP sample unexpected response, and add the country_code
  file_name = File.join(
    File.dirname(__FILE__),
    '../fixtures/geoip_lookup/unexpected_hostip_response.xml')
  response_body = File.read(file_name)

  # Stub request with body
  stub_request(:get, /api.hostip.info/)
    .to_return(status: 200, body: response_body, headers: {})
end

def stub_slow_geoip_lookup
  stub_request(:get, /api.hostip.info/).to_timeout
end

def expect_no_geoip
  expect(UserLocationService).to_not have_received(:location_for_request)
end

def expect_geoip_once
  expect(UserLocationService).to have_received(:location_for_request).once
end
