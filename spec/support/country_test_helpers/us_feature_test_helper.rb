def expect_open_us_day
  expect(page).to have_content("Are US banks closed today?")
  expect(page).to have_content("No. Most US banks are open.")
  expect(page).to have_content("The Federal Reserve Bank schedule is used to determine US bank statuses. Some banks may not adhere to this schedule.")
end

def expect_weekend_us_day
  expect(page).to have_content("Are US banks closed today?")
  expect(page).to have_content("No. Most US banks are closed because of the weekend.")
  expect(page).to have_content("The Federal Reserve Bank schedule is used to determine US bank statuses. Some banks may not adhere to this schedule.")
end

def expect_holiday_us_day(holidays)
  expect(page).to have_content("Are US banks closed today?")
  expect(page).to have_content("No. Most US banks are closed because of #{holidays.to_sentence}.")
  expect(page).to have_content("The Federal Reserve Bank schedule is used to determine US bank statuses. Some banks may not adhere to this schedule.")
end