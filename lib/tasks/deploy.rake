TESTS_FAILED_REGEX = /, [^0].* failure/ # If this matches, the task will assume that tests failed
TESTS_PASSED_REGEX = /0 failures/
ACCEPT_DEPLOY_TEXT = 'DEPLOY' # Text user has to enter to accept the deploy

task :deploy do
  # Run tests and output result
  test_result = DeployCommands.run_tests
  DeployCommands.output(test_result)

  # Fail deploy if any strings matching "(non-zero-number) failure" occurred
  if test_result.match(TESTS_FAILED_REGEX) || !test_result.match(TESTS_PASSED_REGEX)
    fail DeployError, 'Tests did not pass!'
  end

  # Prompt user to accept deploy
  DeployCommands.output('Please review the tests results above.')
  DeployCommands.output("If they are acceptable, type #{ACCEPT_DEPLOY_TEXT} to start the deploy.")

  # If the user accepts the deploy, deploy.
  # Otherwise, abort.
  if STDIN.gets.strip == ACCEPT_DEPLOY_TEXT
    DeployCommands.run_deploy
  else
    fail DeployError, 'User declined deploy!'
  end
end

# Error class for exceptions that occur during a deploy attempt
class DeployError < StandardError; end

###
# Wrapper for various method calls.
# Using a wrapper allows for simple testing (e.g. as calls can be stubbed).
class DeployCommands
  def self.output(message)
    puts message
  end

  def self.run_tests
    `rspec`
  end

  # Push from Github to Heroku
  def self.run_deploy
    `git push banksclosedtoday_heroku master`
  end
end
