def expect_bank_status_check_keen_call(country_code, error: nil)
  params = {
    request: instance_of(ActionDispatch::Request),
    tracking_params: { country_code: country_code, error: error }
  }

  expect_keen_call(:bank_status_check, params)
end
