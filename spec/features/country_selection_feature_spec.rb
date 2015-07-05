require 'spec_helper'

describe 'country selection', type: :feature do
  it "should use the user's country param when provided and show correct messaging" do
    # Make sure GEOIP is not attempted
    expect_no_geoip

    # Go to normal day
    Timecop.travel(Time.parse('January 5, 2015').in_time_zone("Eastern Time (US & Canada)"))

    # Go to page with country param
    visit root_path(country: "US")

    # Make sure correct messaging is shown
    expect_open_us_day
  end

  it 'should use GEOIP lookup otherwise and show correct messaging' do
    # Stub GEOIP
    stub_geoip_lookup("US")

    # Make sure GEOIP is attempted once
    expect_geoip_once

    # Go to normal day
    Timecop.travel(Time.parse('January 5, 2015').in_time_zone("Eastern Time (US & Canada)"))

    # Go to page without country param
    visit root_path

    # Make sure correct messaging is shown (the same as above)
    expect_open_us_day
  end

  context 'when an unsupported country is found' do
    it 'should ask the user to email for support, or provide a different country' do
      # Stub GEOIP with unsupported country
      stub_geoip_lookup("NL")

      # Make sure GEOIP is attempted once
      expect_geoip_once

      # Go to normal day
      Timecop.travel(Time.parse('January 5, 2015').in_time_zone("Eastern Time (US & Canada)"))

      # Go to page without country param
      visit root_path

      # Make sure correct messaging is shown
      expect(page).to_not have_content("Are US banks closed today?")
      expect(page).to_not have_content("The Federal Reserve Bank schedule is used to determine US bank statuses. Some banks may not adhere to this schedule.")
      expect(page).to have_content("Unfortunately, your country isn't supported at this time.")
      expect(page).to have_content("Email us and request support!")
      expect(page).to have_content("Or try a different country?")

      # Try submitting a different country
      select("United States", from: "country")

      # Make sure correct messaging is shown
      expect_open_us_day
    end
  end

  context 'when a country is not found' do
    it 'should ask the user to provide one' do
    end
  end
end
