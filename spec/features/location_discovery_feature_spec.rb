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
      expect_bank_status_check_keen_call('US')
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
      expect_bank_status_check_keen_call('US')
      expect_no_keen_call(:country_lookup_success)
      expect_no_keen_call(:country_lookup_failed)
    end
  end

  context 'when a user does not provide a country_code param' do
    it 'should use GEOIP lookup and show correct messaging' do
      # Stub GEOIP
      stub_geoip_lookup('normal_success', country_code: 'US')

      # Go to normal day
      Timecop.travel(Time.parse('January 5, 2015').in_time_zone('Eastern Time (US & Canada)'))

      # Go to page without country param
      visit root_path

      # Make sure GEOIP was attempted once
      expect_one_geoip_request

      # Make sure correct US messaging is shown
      expect_open_us_day

      # Make sure KeenService was called correctly
      expect_country_lookup_success_keen_call
      expect_no_keen_call(:country_lookup_failed)
      expect_bank_status_check_keen_call('US')

      # Expect no Rollbar notifications
      expect_no_rollbar_notifications
    end

    context 'successful GEOIP lookup country parsing' do
      %w(only_registered_country only_represented_country).each do |type|
        it "should parse the country from #{type} responses correctly" do
          # Stub GEOIP
          stub_geoip_lookup(type, country_code: 'US')

          # Go to normal day
          Timecop.travel(Time.parse('January 5, 2015').in_time_zone('Eastern Time (US & Canada)'))

          # Go to page without country param
          visit root_path

          # Make sure GEOIP was attempted once
          expect_one_geoip_request

          # Make sure correct US messaging is shown
          expect_open_us_day

          # Make sure KeenService was called correctly
          expect_country_lookup_success_keen_call
          expect_no_keen_call(:country_lookup_failed)
          expect_bank_status_check_keen_call('US')

          # Expect no Rollbar notifications
          expect_no_rollbar_notifications
        end
      end
    end

    context 'GEOIP failure handling' do
      %w(invalid_json invalid_lookup_error_json no_country_element no_iso_code).each do |type|
        it "should handle #{type} responses correctly" do
          # Stub a GEOIP rqeuest with the relevant type;
          # store the stubbed response body in a variable.
          stub_geoip_lookup(type)

          # Go to page without country param
          visit root_path

          # Make sure GEOIP was attempted once
          expect_one_geoip_request

          # Make sure correct messaging is shown
          expect_no_country_error

          # Make sure Keen was called correctly
          expect_country_lookup_failed_keen_call(UserLocationService::UnknownResponseFormatError)
          expect_no_keen_call(:country_lookup_success)
          expect_bank_status_check_keen_call(nil, error: :no_country)

          # Make sure Rollbar was notified
          expect_rollbar_call(UserLocationService::UnknownResponseFormatError)
        end
      end

      it 'should handle unknown lookup failures correctly' do
        # Stub a GEOIP rqeuest with an unknown_lookup_error
        stub_geoip_lookup('unknown_lookup_error')

        # Go to page without country param
        visit root_path

        # Make sure GEOIP was attempted once
        expect_one_geoip_request

        # Make sure correct messaging is shown
        expect_no_country_error

        # Make sure Keen was called correctly
        expect_country_lookup_failed_keen_call(UserLocationService::UnknownResponseError)
        expect_no_keen_call(:country_lookup_success)
        expect_bank_status_check_keen_call(nil, error: :no_country)

        # Make sure Rollbar was notified
        expect_rollbar_call(UserLocationService::UnknownResponseError)
      end

      it 'should handle server-failures on GEOIP requests correctly' do
        # Stub a failed GEOIP rqeuest
        stub_server_error_geoip_lookup

        # Go to page without country param
        visit root_path

        # Make sure GEOIP was attempted once
        expect_one_geoip_request

        # Make sure correct messaging is shown
        expect_no_country_error

        # Make sure Keen was called correctly
        expect_country_lookup_failed_keen_call(UserLocationService::UnknownResponseError)
        expect_no_keen_call(:country_lookup_success)
        expect_bank_status_check_keen_call(nil, error: :no_country)

        # Make sure Rollbar was notified
        expect_rollbar_call(UserLocationService::UnknownResponseError)
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
      before do
        # Stub GEOIP with unsupported country
        stub_geoip_lookup('normal_success', country_code: 'NL')
      end

      after do
        # Rollbar should not be called during any of these tests
        expect_no_rollbar_notifications
      end

      context 'when Javascript is enabled', js: true do
        it 'should ask the user to email for support, or provide a different country' do
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

      %w(ip_reserved ip_not_found).each do |type|
        context "with a #{type} error" do
          before do
            # Stub with appropriate error type
            stub_geoip_lookup(type)
          end

          context 'when Javascript is enabled', js: true do
            it 'should ask the user to provide one' do
              # Stub GEOIP with non-existant country
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
              expect_country_lookup_failed_keen_call(UserLocationService::UnknownIpError)
              expect_no_keen_call(:country_lookup_success)
              expect_bank_status_check_keen_call(nil, error: :no_country)
              expect_bank_status_check_keen_call('US')
            end
          end

          context 'when Javascript is not enabled' do
            it 'should do the same thing, but with a manual form submit' do
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
              expect_country_lookup_failed_keen_call(UserLocationService::UnknownIpError)
              expect_no_keen_call(:country_lookup_success)
              expect_bank_status_check_keen_call(nil, error: :no_country)
              expect_bank_status_check_keen_call('US')
            end
          end

          context 'when an unsupported country is then selected' do
            context 'when Javascript is enabled', js: true do
              it 'should ask the user to email for support, or provide a different country' do
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
  end
end
