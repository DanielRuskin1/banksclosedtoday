require 'spec_helper'

describe 'country selection', type: :feature do
  before do
    # Make sure Rollbar is not notified for any exceptions during tests
    expect(Rollbar).to_not receive(:error)

    # Spy on KeenService and UserLocationService during tests
    allow(KeenService).to receive(:track_action).and_call_original
    allow(UserLocationService).to receive(:location_for_request).and_call_original
  end

  def expect_keen_call(occurred, call, params)
    if occurred
      expect(KeenService).to have_received(:track_action).with(call, params)
    else
      expect(KeenService).to_not have_received(:track_action).with(params)
    end
  end

  def expect_country_lookup_success_keen_call(country_code: 'US', occurred: true)
    params = {
      request: instance_of(ActionDispatch::Request),
      tracking_params: { country_code: country_code }
    }

    expect_keen_call(occurred, :country_lookup_success, params)
  end

  def expect_country_lookup_failed_keen_call(error_class, country_code: nil, occurred: true)
    params = {
      request: instance_of(ActionDispatch::Request),
      tracking_params: { country_code: country_code, error: error_class.to_s }
    }

    expect_keen_call(occurred, :country_lookup_failed, params)
  end

  def expect_bank_status_check_keen_call(country_code: 'US', error: nil, occurred: true)
    params = {
      request: instance_of(ActionDispatch::Request),
      tracking_params: { country_code: country_code, error: error }
    }

    expect_keen_call(occurred, :bank_status_check, params)
  end

  it "should use the user's country param when provided and show correct messaging" do
    # Go to normal day
    Timecop.travel(Time.parse('January 5, 2015').in_time_zone('Eastern Time (US & Canada)'))

    # Go to page with country param
    visit root_path(country_code: 'US')

    # Make sure GEOIP was not attempted
    expect_no_geoip

    # Make sure correct messaging is shown
    expect_open_us_day

    # Make sure KeenService was called correctly
    expect_bank_status_check_keen_call
  end

  it 'should not care about case' do
    # Go to normal day
    Timecop.travel(Time.parse('January 5, 2015').in_time_zone('Eastern Time (US & Canada)'))

    # Go to page with country param
    visit root_path(country_code: 'us')

    # Make sure GEOIP was not attempted
    expect_no_geoip

    # Make sure correct messaging is shown
    expect_open_us_day

    # Make sure KeenService was called correctly
    expect_bank_status_check_keen_call
  end

  it 'should use GEOIP lookup otherwise and show correct messaging' do
    # Stub GEOIP
    stub_geoip_lookup('US')

    # Go to normal day
    Timecop.travel(Time.parse('January 5, 2015').in_time_zone('Eastern Time (US & Canada)'))

    # Go to page without country param
    visit root_path

    # Make sure GEOIP was attempted once
    expect_geoip_once

    # Make sure correct messaging is shown (the same as above)
    expect_open_us_day

    # Make sure KeenService was called correctly
    expect_country_lookup_success_keen_call
    expect_bank_status_check_keen_call
  end

  context 'when an unsupported country is found' do
    context 'when Javascript is enabled', js: true do
      it 'should ask the user to email for support, or provide a different country' do
        # Stub GEOIP with unsupported country
        stub_geoip_lookup('NL')

        # Go to normal day
        Timecop.travel(Time.parse('January 5, 2015').in_time_zone('Eastern Time (US & Canada)'))

        # Go to page without country param
        visit root_path

        # Make sure GEOIP was attempted once
        expect_geoip_once

        # Make sure correct messaging is shown
        expect_unsupported_country_error

        # No "Go" buttons should be displayed, as the user has JS
        expect(page).to_not have_button('Go!')

        # Try submitting a different country - an auto-submit should occur
        select('United States', from: 'country_code')

        # GEOIP should not have been attempted again
        # (e.g. and should still be at 1 call total)
        expect_geoip_once

        # Make sure correct messaging is shown
        expect_open_us_day

        # Make sure KeenService was called correctly
        expect_country_lookup_success_keen_call(country_code: 'NL')
        expect_bank_status_check_keen_call(country_code: 'NL', error: :unsupported_country)
        expect_bank_status_check_keen_call(country_code: 'US')
      end
    end

    context 'when Javascript is not enabled' do
      it 'should do the same thing, but with a manual form submit' do
        # Stub GEOIP with unsupported country
        stub_geoip_lookup('NL')

        # Go to normal day
        Timecop.travel(Time.parse('January 5, 2015').in_time_zone('Eastern Time (US & Canada)'))

        # Go to page without country param
        visit root_path

        # Make sure GEOIP was attempted once
        expect_geoip_once

        # Make sure correct messaging is shown
        expect_unsupported_country_error

        # Try choosing a different country
        select('United States', from: 'country_code')

        # Manually submit form
        click_button('Go!')

        # GEOIP should not have been attempted again
        # (e.g. and should still be at 1 call total)
        expect_geoip_once

        # Make sure correct messaging is shown
        expect_open_us_day

        # Make sure KeenService was called correctly
        expect_country_lookup_success_keen_call(country_code: 'NL')
        expect_bank_status_check_keen_call(country_code: 'NL', error: :unsupported_country)
        expect_bank_status_check_keen_call(country_code: 'US')
      end
    end
  end

  context 'when a country is not found' do
    context 'when Javascript is enabled', js: true do
      it 'should ask the user to provide one' do
        # Stub GEOIP with non-existant country
        stub_geoip_lookup('XX')

        # Go to normal day
        Timecop.travel(Time.parse('January 5, 2015').in_time_zone('Eastern Time (US & Canada)'))

        # Go to page without country param
        visit root_path

        # Make sure GEOIP was attempted once
        expect_geoip_once

        # Make sure correct messaging is shown
        expect_no_country_error

        # No "Go" buttons should be displayed, as the user has JS
        expect(page).to_not have_button('Go!')

        # Try submitting a different country - an auto-submit should occur
        select('United States', from: 'country_code')

        # GEOIP should not have been attempted again
        # (e.g. and should still be at 1 call total)
        expect_geoip_once

        # Make sure correct messaging is shown
        expect_open_us_day

        # Make sure KeenService was called correctly
        expect_country_lookup_failed_keen_call(UserLocationService::ReceivedBadCountryError)
        expect_bank_status_check_keen_call(country_code: nil, error: :no_country)
        expect_bank_status_check_keen_call(country_code: 'US')
      end
    end

    context 'when Javascript is not enabled' do
      it 'should do the same thing, but with a manual form submit' do
        # Stub GEOIP with non-existant country
        stub_geoip_lookup('XX')

        # Go to normal day
        Timecop.travel(Time.parse('January 5, 2015').in_time_zone('Eastern Time (US & Canada)'))

        # Go to page without country param
        visit root_path

        # Make sure GEOIP was attempted once
        expect_geoip_once

        # Make sure correct messaging is shown
        expect_no_country_error

        # Try choosing a different country
        select('United States', from: 'country_code')

        # Manually submit form
        click_button('Go!')

        # GEOIP should not have been attempted again
        # (e.g. and should still be at 1 call total)
        expect_geoip_once

        # Make sure correct messaging is shown
        expect_open_us_day

        # Make sure KeenService was called correctly
        expect_country_lookup_failed_keen_call(UserLocationService::ReceivedBadCountryError)
        expect_bank_status_check_keen_call(country_code: nil, error: :no_country)
        expect_bank_status_check_keen_call(country_code: 'US')
      end
    end
  end
end
