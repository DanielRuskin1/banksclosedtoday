def expect_no_country_error
  expect(page).to_not have_content('Are US banks closed today?')
  expect(page).to_not have_content('The Federal Reserve Bank schedule is used to determine US bank statuses. Some banks may not adhere to this schedule.')
  expect(page).to have_content("We weren't able to figure out where you are in the world.")
  expect(page).to have_content('Can you tell us?')
end

def expect_unsupported_country_error
  expect(page).to_not have_content('Are US banks closed today?')
  expect(page).to_not have_content('The Federal Reserve Bank schedule is used to determine US bank statuses. Some banks may not adhere to this schedule.')
  expect(page).to have_content("Unfortunately, your country isn't supported at this time.")
  expect(page).to have_content('Email us and request support!')
  expect(page).to have_content('Try another country?')
end