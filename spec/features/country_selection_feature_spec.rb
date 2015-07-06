require 'spec_helper'

describe 'country selection', type: :feature do
  it "should use the user's country param when provided and show correct messaging" do
    # Make sure GEOIP is not attempted
    expect_no_geoip

    # Go to normal day
    Timecop.travel(Time.parse('January 5, 2015').in_time_zone('Eastern Time (US & Canada)'))

    # Go to page with country param
    visit root_path(country: 'US')

    # Make sure correct messaging is shown
    expect_open_us_day
  end

  it 'should use GEOIP lookup otherwise and show correct messaging' do
    # Stub GEOIP
    stub_geoip_lookup('US')

    # Make sure GEOIP is attempted once
    expect_geoip_once

    # Go to normal day
    Timecop.travel(Time.parse('January 5, 2015').in_time_zone('Eastern Time (US & Canada)'))

    # Go to page without country param
    visit root_path

    # Make sure correct messaging is shown (the same as above)
    expect_open_us_day
  end

  context 'when an unsupported country is found' do
    context 'when Javascript is enabled', js: true do
      it 'should ask the user to email for support, or provide a different country' do
        # Stub GEOIP with unsupported country
        stub_geoip_lookup('NL')

        # Make sure GEOIP is attempted once
        expect_geoip_once

        # Go to normal day
        Timecop.travel(Time.parse('January 5, 2015').in_time_zone('Eastern Time (US & Canada)'))

        # Go to page without country param
        visit root_path

        # Make sure correct messaging is shown
        expect_unsupported_country_error

        # No "Go" buttons should be displayed, as the user has JS
        expect(page).to_not have_button('Go!')

        # Try submitting a different country - an auto-submit should occur
        select('United States', from: 'country')

        # Make sure correct messaging is shown
        expect_open_us_day
      end
    end

    context "when Javascript is not enabled" do
      it "should do the same thing, but with a manual form submit" do
        # Stub GEOIP with unsupported country
        stub_geoip_lookup('NL')

        # Make sure GEOIP is attempted once
        expect_geoip_once

        # Go to normal day
        Timecop.travel(Time.parse('January 5, 2015').in_time_zone('Eastern Time (US & Canada)'))

        # Go to page without country param
        visit root_path

        # Make sure correct messaging is shown
        expect_unsupported_country_error

        # Try choosing a different country
        select('United States', from: 'country')

        # Manually submit form
        click_button("Go!")

        # Make sure correct messaging is shown
        expect_open_us_day
      end
    end
  end

  context 'when a country is not found' do
    context 'when Javascript is enabled', js: true do
      it 'should ask the user to provide one' do
        # Stub GEOIP with non-existant country
        stub_geoip_lookup('XX')

        # Make sure GEOIP is attempted once
        expect_geoip_once

        # Go to normal day
        Timecop.travel(Time.parse('January 5, 2015').in_time_zone('Eastern Time (US & Canada)'))

        # Go to page without country param
        visit root_path

        # Make sure correct messaging is shown
        expect_no_country_error

        # No "Go" buttons should be displayed, as the user has JS
        expect(page).to_not have_button('Go!')

        # Try submitting a different country - an auto-submit should occur
        select('United States', from: 'country')

        # Make sure correct messaging is shown
        expect_open_us_day
      end
    end

    context "when Javascript is not enabled" do
      it "should do the same thing, but with a manual form submit" do
        # Stub GEOIP with non-existant country
        stub_geoip_lookup('XX')

        # Make sure GEOIP is attempted once
        expect_geoip_once

        # Go to normal day
        Timecop.travel(Time.parse('January 5, 2015').in_time_zone('Eastern Time (US & Canada)'))

        # Go to page without country param
        visit root_path

        # Make sure correct messaging is shown
        expect_no_country_error

        # Try choosing a different country
        select('United States', from: 'country')

        # Manually submit form
        click_button("Go!")

        # Make sure correct messaging is shown
        expect_open_us_day
      end
    end
  end
end
