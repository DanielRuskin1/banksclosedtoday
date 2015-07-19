FAILED_TESTS_REGEX = /, [^0].* failure/ # If this matches, the task will assume that tests failed
ACCEPT_DEPLOY_TEXT = "DEPLOY" # Text user has to enter to accept the deploy

task :deploy do
  # Run tests and output result
  test_result = DeployCommands.run_tests
  DeployCommands.output(test_result)

  # Fail deploy if any strings matching "(non-zero-number) failure" occurred
  raise DeployError, "Tests failed!" if test_result.match(FAILED_TESTS_REGEX)

  # Prompt user to accept deploy
  DeployCommands.output('Please review the above tests results.')
  DeployCommands.output("If they are acceptable, type #{ACCEPT_DEPLOY_TEXT}.")

  # If the user accepts the deploy, deploy.
  # Otherwise, abort.
  if STDIN.gets.strip == ACCEPT_DEPLOY_TEXT
    DeployCommands.run_deploy
  else
    raise DeployError, "User declined deploy!"
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

  def self.run_deploy
    `git push banksclosedtoday_heroku master`
  end
end
