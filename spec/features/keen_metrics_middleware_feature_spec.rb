require 'spec_helper'

describe 'KeenMetrics middleware', type: :feature do
  before do
    # Spy on KeenService and Rollbar during this test
    spy_on_keen
    spy_on_rollbar
  end

  after do
    # Make sure Rollbar was not notified with any errors during tets
    expect_no_rollbar
  end

  it 'should notify Keen on each request' do
    # Go to front page with a country param
    visit root_path(country_code: 'US')

    # Make sure KeenService was called with the correct params
    expect_keen_call(:page_visit, request: instance_of(ActionDispatch::Request))
  end
end
