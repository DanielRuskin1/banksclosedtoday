def spy_on_rollbar
  allow(Rollbar).to receive(:error).and_call_original
end

def expect_rollbar_call(error_class)
  expect(Rollbar).to have_received(:error).with(error_class)
end

def expect_no_rollbar_notifications
  expect(Rollbar).to_not have_received(:error)
end
