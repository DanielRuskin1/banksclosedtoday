def stub_geoip_lookup(country_code)
  stub_request(:get, /api.hostip.info/)
    .to_return(status: 200, body: country_code, headers: {})
end

def expect_no_geoip
  expect(UserLocationService).to_not have_received(:location_for_request)
end

def expect_geoip_once
  expect(UserLocationService).to have_received(:location_for_request).once
end
