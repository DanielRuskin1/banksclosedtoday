require 'spec_helper'

describe 'US bank holidays', type: :feature do
  before do
    # Stub GEOIP lookup to US for this test
    stub_geoip_lookup('normal_success', country_code: 'US')

    # Spy on Rollbar for this test
    spy_on_rollbar
  end

  after do
    # Make sure Rollbar was not notified for any exceptions during tests
    expect_no_rollbar_notifications
  end

  describe 'regular bank holidays' do
    it 'should show bank-closed messaging when an observed holiday applies' do
      # Go to Thanksgiving Day
      Timecop.travel(Time.parse('November 26, 2015').in_time_zone('Eastern Time (US & Canada)'))

      # Go to banks#index page
      visit root_path

      # Verify that correct messaging is displayed
      expect(page).to have_content('Yes.')
      expect_holiday_us_day(['Thanksgiving'])
    end

    it 'should handle simultaneous holidays correctly' do
      # Import sample coinciding holidays
      Holidays.load_custom(File.join(File.dirname(__FILE__), '../fixtures/holiday_definitions/holidays_coinciding_with_thanksgiving.yaml'))

      # Go to January 12, 2015
      Timecop.travel(Time.parse('November 26, 2015').in_time_zone('Eastern Time (US & Canada)'))

      # Verify import
      expect(DateTime.now.holidays(:us).count).to eq(3)

      # Go to banks#index page
      visit root_path

      # Verify that correct messaging is displayed
      expect(page).to have_content('Yes.')
      expect_holiday_us_day(['Thanksgiving', 'Independence Day', 'Veterans Day'])
    end

    it 'should not show bank-closed messaging when a non-observed holiday applies' do
      # Import sample unobserved holiday
      Holidays.load_custom(File.join(File.dirname(__FILE__), '../fixtures/holiday_definitions/sample_unobserved_holiday.yaml'))

      # Go to January 12, 2015
      Timecop.travel(Time.parse('January 12, 2015').in_time_zone('Eastern Time (US & Canada)'))

      # Verify import
      expect(DateTime.now.holidays(:us).first[:name]).to eq('Daniel Day')

      # Go to banks#index page
      visit root_path

      # Verify that correct messaging is displayed
      expect_open_us_day
    end

    it 'should not show bank-closed messaging when no holidays apply' do
      # Go to normal day
      Timecop.travel(Time.parse('January 5, 2015').in_time_zone('Eastern Time (US & Canada)'))

      # Go to banks#index page
      visit root_path

      # Verify that correct messaging is displayed
      expect_open_us_day
    end
  end

  describe 'bank holidays falling on a Saturday' do
    it 'should show bank-closed messaging the day before' do
      # Test July 3rd, 2015 (Friday before Independence Day)
      Timecop.travel(Time.parse('July 3, 2015').in_time_zone('Eastern Time (US & Canada)'))

      # Go to banks#index page
      visit root_path

      # Verify that correct messaging is displayed
      expect_holiday_us_day(['Independence Day'])

      # Test November 10th, 2017 (Friday before Veterans day)
      Timecop.travel(Time.parse('November 10, 2017').in_time_zone('Eastern Time (US & Canada)'))

      # Go to banks#index page
      visit root_path

      # Verify that correct messaging is displayed
      expect_holiday_us_day(['Veterans Day'])
    end
  end

  describe 'bank holidays falling on a Sunday' do
    it 'should show bank-closed messaging the day after' do
      # Test July 4rd, 2021 (Monday after Independence Day)
      Timecop.travel(Time.parse('July 5, 2021').in_time_zone('Eastern Time (US & Canada)'))

      # Go to banks#index page
      visit root_path

      # Verify that correct messaging is displayed
      expect_holiday_us_day(['Independence Day'])
    end
  end
end
