def stub_geoip_lookup(country_code)
  stub_request(:get, /api.hostip.info/)
    .to_return(status: 200, body: country_code, headers: {})
end

def expect_no_geoip
  expect(UserCountryService).to_not receive(:country_for_ip)
end

def expect_geoip_once
  expect(UserCountryService).to receive(:country_for_ip).once.and_call_original
end
