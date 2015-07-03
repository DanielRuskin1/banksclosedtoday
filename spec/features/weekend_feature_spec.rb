require 'spec_helper'

describe "weekend", :feature do
  it "should show bank-closed messaging on Saturday" do
    # Go to Saturday
    Timecop.travel(Time.parse("July 11, 2015").in_time_zone)

    # Go to banks#index page
    visit root_path

    # Verify that correct messaging is displayed
    expect(page).to have_content("Yes.")
    expect(page).to have_content("Banks are closed as today is not a weekday.")
  end

  it "should show bank-closed messaging on Sunday" do
    # Go to Sunday
    Timecop.travel(Time.parse("July 12, 2015").in_time_zone)

    # Go to banks#index page
    visit root_path

    # Verify that correct messaging is displayed
    expect(page).to have_content("Yes.")
    expect(page).to have_content("Banks are closed as today is not a weekday.")
  end

  it "should show bank-closed messaging on other days" do
    # Go to Monday
    Timecop.travel(Time.parse("July 13, 2015").in_time_zone)

    # Go to banks#index page
    visit root_path

    # Verify that correct messaging is displayed
    expect(page).to have_content("No.")
    expect(page).to have_content("Banks are open today.")
  end
end