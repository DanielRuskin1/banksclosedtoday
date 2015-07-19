require 'spec_helper'

describe 'country discovery', type: :feature do
  before do
    # Spy on KeenService, Rollbar, and UserLocationService during tests
    spy_on_keen
    spy_on_rollbar
    allow(UserLocationService).to receive(:location_for_request).and_call_original
  end

  context 'when a user provides a country_code param' do
    after do
      # Expect no Rollbar notifications
      expect_no_rollbar_notifications
    end

    it 'should use the param and show correct messaging' do
      # Go to normal day
      Timecop.travel(Time.parse('January 5, 2015').in_time_zone('Eastern Time (US & Canada)'))

      # Go to page with country param
      visit root_path(country_code: 'US')

      # Make sure GEOIP was not attempted
      expect_no_geoip_requests

      # Make sure correct messaging is shown
      expect_open_us_day

      # Make sure KeenService was called correctly
      expect_bank_status_check_keen_call("US")
      expect_no_keen_call(:country_lookup_success)
      expect_no_keen_call(:country_lookup_failed)
    end

    it 'should ignore case' do
      # Go to normal day
      Timecop.travel(Time.parse('January 5, 2015').in_time_zone('Eastern Time (US & Canada)'))

      # Go to page with country param
      visit root_path(country_code: 'us')

      # Make sure GEOIP was not attempted
      expect_no_geoip_requests

      # Make sure correct messaging is shown
      expect_open_us_day

      # Make sure KeenService was called correctly
      expect_bank_status_check_keen_call("US")
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
      expect_one_geoip_request

      # Make sure correct messaging is shown (the same as above)
      expect_open_us_day

      # Make sure KeenService was called correctly
      expect_country_lookup_success_keen_call
      expect_no_keen_call(:country_lookup_failed)
      expect_bank_status_check_keen_call("US")

      # Expect no Rollbar notifications
      expect_no_rollbar_notifications
    end

    context 'request failure handling' do
      it 'should handle failed GEOIP requests correctly' do
        # Stub a failed GEOIP rqeuest
        stub_failed_geoip_lookup

        # Go to page without country param
        visit root_path

        # Make sure GEOIP was attempted once
        expect_one_geoip_request

        # Make sure correct messaging is shown
        expect_no_country_error

        # Make sure Keen was called correctly
        expect_country_lookup_failed_keen_call(Faraday::ResourceNotFound)
        expect_no_keen_call(:country_lookup_success)
        expect_bank_status_check_keen_call(nil, error: :no_country)

        # Make sure Rollbar was notified
        expect_rollbar_call(Faraday::ResourceNotFound)
      end

      ["invalid_xml", "no_result_set_element", "no_feature_member_element", "no_hostip_element", "no_country_code_element"].each do |type|
        it "should handle foo format responses correctly" do
          # Stub a GEOIP rqeuest with the relevant type;
          # store the stubbed response body in a variable.
          response_body = stub_invalid_format_geoip_lookup(type)

          # Go to page without country param
          visit root_path

          # Make sure GEOIP was attempted once
          expect_one_geoip_request

          # Make sure correct messaging is shown
          expect_no_country_error

          # Make sure Keen was called correctly
          expect_country_lookup_failed_keen_call(UserLocationService::UnknownResponseFormat)
          expect_no_keen_call(:country_lookup_success)
          expect_bank_status_check_keen_call(nil, error: :no_country)

          # Make sure Rollbar was notified
          expect_rollbar_call(UserLocationService::UnknownResponseFormat)
        end
      end

      it 'should handle slow GEOIP requests correctly' do
        # Stub a slow GEOIP rqeuest
        stub_slow_geoip_lookup

        # Go to page without country param
        visit root_path

        # Make sure GEOIP was attempted once
        expect_one_geoip_request

        # Make sure correct messaging is shown
        expect_no_country_error

        # Make sure Keen was called correctly
        expect_country_lookup_failed_keen_call(Faraday::TimeoutError)
        expect_no_keen_call(:country_lookup_success)
        expect_bank_status_check_keen_call(nil, error: :no_country)

        # Make sure Rollbar was notified
        expect_rollbar_call(Faraday::TimeoutError)
      end
    end

    context 'when an unsupported country is found' do
      after do
        # Rollbar should not be called during any of these tests
        expect_no_rollbar_notifications
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
          expect_one_geoip_request

          # Make sure correct messaging is shown
          expect_unsupported_country_error

          # No "Go" buttons should be displayed, as the user has JS
          expect(page).to_not have_button('Go!')

          # Try submitting a different country - an auto-submit should occur
          select('United States', from: 'country_code')

          # GEOIP should not have been attempted again
          # (e.g. and should still be at 1 call total)
          expect_one_geoip_request

          # Make sure correct messaging is shown
          expect_open_us_day

          # Make sure KeenService was called correctly
          expect_country_lookup_success_keen_call(country_code: 'NL')
          expect_no_keen_call(:country_lookup_failed)
          expect_bank_status_check_keen_call('NL', error: :unsupported_country)
          expect_bank_status_check_keen_call('US')
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
          expect_one_geoip_request

          # Make sure correct messaging is shown
          expect_unsupported_country_error

          # Try choosing a different country
          select('United States', from: 'country_code')

          # Manually submit form
          click_button('Go!')

          # GEOIP should not have been attempted again
          # (e.g. and should still be at 1 call total)
          expect_one_geoip_request

          # Make sure correct messaging is shown
          expect_open_us_day

          # Make sure KeenService was called correctly
          expect_country_lookup_success_keen_call(country_code: 'NL')
          expect_no_keen_call(:country_lookup_failed)
          expect_bank_status_check_keen_call('NL', error: :unsupported_country)
          expect_bank_status_check_keen_call('US')
        end
      end
    end

    context 'when a country is not found' do
      after do
        # Rollbar should not be called during any of these tests
        expect_no_rollbar_notifications
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
          expect_one_geoip_request

          # Make sure correct messaging is shown
          expect_no_country_error

          # No "Go" buttons should be displayed, as the user has JS
          expect(page).to_not have_button('Go!')

          # Try submitting a different country - an auto-submit should occur
          select('United States', from: 'country_code')

          # GEOIP should not have been attempted again
          # (e.g. and should still be at 1 call total)
          expect_one_geoip_request

          # Make sure correct messaging is shown
          expect_open_us_day

          # Make sure KeenService was called correctly
          expect_country_lookup_failed_keen_call(UserLocationService::ReceivedBadCountryError)
          expect_no_keen_call(:country_lookup_success)
          expect_bank_status_check_keen_call(nil, error: :no_country)
          expect_bank_status_check_keen_call('US')
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
          expect_one_geoip_request

          # Make sure correct messaging is shown
          expect_no_country_error

          # Try choosing a different country
          select('United States', from: 'country_code')

          # Manually submit form
          click_button('Go!')

          # GEOIP should not have been attempted again
          # (e.g. and should still be at 1 call total)
          expect_one_geoip_request

          # Make sure correct messaging is shown
          expect_open_us_day

          # Make sure KeenService was called correctly
          expect_country_lookup_failed_keen_call(UserLocationService::ReceivedBadCountryError)
          expect_no_keen_call(:country_lookup_success)
          expect_bank_status_check_keen_call(nil, error: :no_country)
          expect_bank_status_check_keen_call('US')
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
            expect_one_geoip_request

            # Make sure correct messaging is shown
            expect_no_country_error

            # No "Go" buttons should be displayed, as the user has JS
            expect(page).to_not have_button('Go!')

            # Try choosing an unsupported country
            select('Other', from: 'country_code')

            # GEOIP should not have been attempted again
            # (e.g. and should still be at 1 call total)
            expect_one_geoip_request

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
            expect_one_geoip_request

            # Make sure correct messaging is shown
            expect_no_country_error

            # Try choosing an unsupported country
            select('Other', from: 'country_code')

            # Manually submit form
            click_button('Go!')

            # GEOIP should not have been attempted again
            # (e.g. and should still be at 1 call total)
            expect_one_geoip_request

            # Make sure correct messaging is shown
            expect_unsupported_country_error
          end
        end
      end
    end
  end
end
