require 'spec_helper'

describe 'country selection', type: :feature do
  before do
    # Spy on KeenService, Rollbar, and UserLocationService during tests
    allow(KeenService).to receive(:track_action).and_call_original
    allow(Rollbar).to receive(:error).and_call_original
    allow(UserLocationService).to receive(:location_for_request).and_call_original
  end

  def expect_country_lookup_success_keen_call(country_code: 'US')
    params = {
      request: instance_of(ActionDispatch::Request),
      tracking_params: { country_code: country_code }
    }

    expect_keen_call(:country_lookup_success, params)
  end

  def expect_country_lookup_failed_keen_call(error_class, error_message, country_code: nil)
    params = {
      request: instance_of(ActionDispatch::Request),
      tracking_params: { country_code: country_code, error: error_class.to_s, error_message: error_message }
    }

    expect_keen_call(:country_lookup_failed, params)
  end

  def expect_bank_status_check_keen_call(country_code: 'US', error: nil)
    params = {
      request: instance_of(ActionDispatch::Request),
      tracking_params: { country_code: country_code, error: error }
    }

    expect_keen_call(:bank_status_check, params)
  end

  context 'when a user provides a country_code param' do
    it 'should use the param and show correct messaging' do
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
      expect_no_keen_call(:country_lookup_success)
      expect_no_keen_call(:country_lookup_failed)
    end

    it 'should ignore case' do
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
      expect_no_keen_call(:country_lookup_success)
      expect_no_keen_call(:country_lookup_failed)
    end
  end

  context 'when a user does not provide a country_code param' do
    it 'should use GEOIP lookup and show correct messaging' do
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
      expect_no_keen_call(:country_lookup_failed)
      expect_bank_status_check_keen_call

      # Expect no Rollbar notifications
      expect_no_rollbar
    end

    context 'request failure handling' do
      it 'should handle failed GEOIP requests correctly' do
        # Stub a failed GEOIP rqeuest
        stub_failed_geoip_lookup

        # Go to page without country param
        visit root_path

        # Make sure GEOIP was attempted once
        expect_geoip_once

        # Make sure correct messaging is shown
        expect_no_country_error

        # Make sure Keen was called correctly
        expect_country_lookup_failed_keen_call(Faraday::ClientError, 'the server responded with status 500')
        expect_no_keen_call(:country_lookup_success)
        expect_bank_status_check_keen_call(country_code: nil, error: :no_country)
      end

      it 'should handle invalid XML responses correctly' do
        # Stub a GEOIP rqeuest with invalid XML
        stub_geoip_lookup_with_invalid_xml

        # Go to page without country param
        visit root_path

        # Make sure GEOIP was attempted once
        expect_geoip_once

        # Make sure correct messaging is shown
        expect_no_country_error

        # Make sure Keen was called correctly
        expect_country_lookup_failed_keen_call(UserLocationService::UnknownResponseFormat, 'BadXML')
        expect_no_keen_call(:country_lookup_success)
        expect_bank_status_check_keen_call(country_code: nil, error: :no_country)

        # Make sure Rollbar was notified
        expect(Rollbar).to have_received(:error).with(instance_of(UserLocationService::UnknownResponseFormat))
      end

      it 'should handle valid - but unexpected - XML responses correctly' do
        # Stub a GEOIP rqeuest with unexpected XML
        stub_geoip_lookup_with_unexpected_xml

        # Go to page without country param
        visit root_path

        # Make sure GEOIP was attempted once
        expect_geoip_once

        # Make sure correct messaging is shown
        expect_no_country_error

        # Make sure Keen was called correctly
        expect_country_lookup_failed_keen_call(UserLocationService::UnknownResponseFormat, "<?xml version=\"1.0\" encoding=\"ISO-8859-1\" ?>\n<foo>Bar</foo>")
        expect_no_keen_call(:country_lookup_success)
        expect_bank_status_check_keen_call(country_code: nil, error: :no_country)

        # Make sure Rollbar was notified
        expect(Rollbar).to have_received(:error).with(instance_of(UserLocationService::UnknownResponseFormat))
      end

      it 'should handle slow GEOIP requests correctly' do
        # Stub a slow GEOIP rqeuest
        stub_slow_geoip_lookup

        # Go to page without country param
        visit root_path

        # Make sure GEOIP was attempted once
        expect_geoip_once

        # Make sure correct messaging is shown
        expect_no_country_error

        # Make sure Keen was called correctly
        expect_country_lookup_failed_keen_call(Faraday::TimeoutError, 'execution expired')
        expect_no_keen_call(:country_lookup_success)
        expect_bank_status_check_keen_call(country_code: nil, error: :no_country)

        # Expect no Rollbar notifications
        expect_no_rollbar
      end
    end

    context 'when an unsupported country is found' do
      after do
        # Rollbar should not be called during any of these tests
        expect_no_rollbar
      end

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
          expect_no_keen_call(:country_lookup_failed)
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
          expect_no_keen_call(:country_lookup_failed)
          expect_bank_status_check_keen_call(country_code: 'NL', error: :unsupported_country)
          expect_bank_status_check_keen_call(country_code: 'US')
        end
      end
    end

    context 'when a country is not found' do
      after do
        # Rollbar should not be called during any of these tests
        expect_no_rollbar
      end

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
          expect_country_lookup_failed_keen_call(UserLocationService::ReceivedBadCountryError, 'XX')
          expect_no_keen_call(:country_lookup_success)
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
          expect_country_lookup_failed_keen_call(UserLocationService::ReceivedBadCountryError, 'XX')
          expect_no_keen_call(:country_lookup_success)
          expect_bank_status_check_keen_call(country_code: nil, error: :no_country)
          expect_bank_status_check_keen_call(country_code: 'US')
        end
      end

      context 'when an unsupported country is then selected' do
        context 'when Javascript is enabled', js: true do
          it 'should ask the user to email for support, or provide a different country' do
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

            # Try choosing an unsupported country
            select('Other', from: 'country_code')

            # GEOIP should not have been attempted again
            # (e.g. and should still be at 1 call total)
            expect_geoip_once

            # Make sure correct messaging is shown
            expect_unsupported_country_error
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

            # Try choosing an unsupported country
            select('Other', from: 'country_code')

            # Manually submit form
            click_button('Go!')

            # GEOIP should not have been attempted again
            # (e.g. and should still be at 1 call total)
            expect_geoip_once

            # Make sure correct messaging is shown
            expect_unsupported_country_error
          end
        end
      end
    end
  end
end
