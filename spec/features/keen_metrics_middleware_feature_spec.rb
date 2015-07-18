require 'spec_helper'

describe 'KeenMetrics middleware', type: :feature do
  before do
    # Spy on KeenService and Rollbar during this test
    allow(KeenService).to receive(:track_action).and_call_original
    allow(Rollbar).to receive(:error).and_call_original
  end

  after do
    # Make sure Rollbar was not notified with any errors during tets
    expect_no_rollbar
  end

  it 'should notify Keen on each request' do
    # Go to front page with a country param
    visit root_path(country_code: 'US')

    # Make sure KeenService was called with the correct params
    expect(KeenService).to have_received(:track_action).with(:page_visit, request: instance_of(ActionDispatch::Request))
  end
end
