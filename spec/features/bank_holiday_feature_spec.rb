require 'spec_helper'

describe "bank holidays", type: :feature do
  describe "regular bank holidays" do
    it "should show bank-closed messaging when an observed holiday applies" do
      # Go to Thanksgiving Day
      Timecop.travel(Time.parse("November 26, 2015").in_time_zone)

      # Go to banks#index page
      visit root_path

      # Verify that correct messaging is displayed
      expect(page).to have_content("Yes.")
      expect(page).to have_content("Banks are closed today due to the following holiday: Thanksgiving.")
    end

    it "should not show bank-closed messaging when a non-observed holiday applies" do
      # Import sample unobserved holiday
      Holidays.load_custom(File.join(File.dirname(__FILE__), "../fixtures/holiday_definitions/sample_unobserved_holiday.yaml"))

      # Go to January 12, 2015
      # This should now be Daniel Day.
      Timecop.travel(Time.parse("January 12, 2015").in_time_zone)

      # Verify import
      expect(DateTime.now.holidays(:us).first[:name]).to eq("Daniel Day")

      # Go to banks#index page
      visit root_path

      # Verify that correct messaging is displayed
      expect(page).to have_content("No.")
      expect(page).to have_content("Banks are open today.")
    end

    it "should not show bank-closed messaging when no holidays apply" do
      # Go to normal day
      Timecop.travel(Time.parse("January 5, 2015").in_time_zone)

      # Go to banks#index page
      visit root_path

      # Verify that correct messaging is displayed
      expect(page).to have_content("No.")
      expect(page).to have_content("Banks are open today.")
    end
  end

  describe "bank holidays falling on a Saturday" do
    it "should show bank-closed messaging the day before" do
      # Test July 3rd, 2015 (Friday before Independance Day)
      Timecop.travel(Time.parse("July 3, 2015").in_time_zone)

      # Go to banks#index page
      visit root_path

      # Verify that correct messaging is displayed
      expect(page).to have_content("Yes.")
      expect(page).to have_content("Banks are closed today due to the following holiday: Independence Day.")

      # Test November 10th, 2017 (Saturday before Veterans day)
      Timecop.travel(Time.parse("November 10, 2017").in_time_zone)

      # Go to banks#index page
      visit root_path

      # Verify that correct messaging is displayed
      expect(page).to have_content("Yes.")
      expect(page).to have_content("Banks are closed today due to the following holiday: Veterans Day.")
    end
  end

  describe "bank holidays falling on a Sunday" do
    it "should show bank-closed messaging the day after" do
      # Test July 4rd, 2021 (Monday after Independance Day)
      Timecop.travel(Time.parse("July 5, 2021").in_time_zone)

      # Go to banks#index page
      visit root_path

      # Verify that correct messaging is displayed
      expect(page).to have_content("Yes.")
      expect(page).to have_content("Banks are closed today due to the following holiday: Independence Day.")
    end
  end
end