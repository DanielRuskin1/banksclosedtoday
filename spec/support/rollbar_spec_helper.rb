def expect_no_rollbar
  expect(Rollbar).to_not have_received(:error)
end
