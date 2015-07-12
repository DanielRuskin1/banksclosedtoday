def expect_keen_call(tracked_action, params)
  expect(KeenService).to have_received(:track_action).with(tracked_action, params)
end

def expect_no_keen_call(tracked_action)
  expect(KeenService).to_not have_received(:track_action).with(tracked_action, any_args)
end
