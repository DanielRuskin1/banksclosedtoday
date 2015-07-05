require 'spec_helper'

describe 'weekends', :feature do
  context 'US' do
    before do
      stub_geoip_lookup('US')
    end

    it 'should show bank-closed messaging on Saturday' do
      # Go to Saturday
      Timecop.travel(Time.parse('July 11, 2015').in_time_zone('Eastern Time (US & Canada)'))

      # Go to banks#index page
      visit root_path

      # Verify that correct messaging is displayed
      expect_weekend_us_day
    end

    it 'should show bank-closed messaging on Sunday' do
      # Go to Sunday
      Timecop.travel(Time.parse('July 12, 2015').in_time_zone('Eastern Time (US & Canada)'))

      # Go to banks#index page
      visit root_path

      # Verify that correct messaging is displayed
      expect_weekend_us_day
    end

    it 'should not show bank-closed messaging on other days' do
      # Go to Monday
      Timecop.travel(Time.parse('July 13, 2015').in_time_zone('Eastern Time (US & Canada)'))

      # Go to banks#index page
      visit root_path

      # Verify that correct messaging is displayed
      expect_open_us_day
    end
  end
end
