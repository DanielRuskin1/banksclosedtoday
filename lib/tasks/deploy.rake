TESTS_FAILED_REGEX = /, [^0].* failure/ # If this matches, the task will assume that tests failed
TESTS_PASSED_REGEX = /0 failures/
ACCEPT_DEPLOY_TEXT = 'DEPLOY' # Text user has to enter to accept the deploy

# Error class for exceptions that can occur during a deploy attempt
class DeployError < StandardError; end

task :deploy do
  # Check for uncommited changes
  check_for_uncommited_changes

  # Run/verify tests
  run_and_verify_tests

  # Prompt user to accept deploy
  prompt_user_to_complete_deploy
end

###
# Helper method for:
# 1. Checking whether any uncommited changes are present in git, and
# 2. Raising an exception if so.
def check_for_uncommited_changes
  fail DeployError, 'Please commit changes before deploying.' if DeployCommands.git_status.present?
end

###
# Helper method for:
# 1. Running tests and outputting the results, and
# 2. Raising an exception if any tests failed.
def run_and_verify_tests
  # Run tests and output result
  test_result = DeployCommands.run_tests
  DeployCommands.output(test_result)

  # Fail deploy if any strings matching "(non-zero-number) failure" occurred
  fail DeployError, 'Tests did not pass!' if test_result.match(TESTS_FAILED_REGEX) || !test_result.match(TESTS_PASSED_REGEX)
end

###
# Helper method for:
# 1. Prompting the user to complete the deploy, and
#      a. Completing the deploy if the user accepts, or
#      b. Raising an exception if the user declines.
def prompt_user_to_complete_deploy
  # Prompt user to accept deploy
  DeployCommands.output("Please review any output above, then type #{ACCEPT_DEPLOY_TEXT} to start the deploy.")

  # If the user accepts the deploy, deploy.
  # Otherwise, abort.
  if DeployCommands.input == ACCEPT_DEPLOY_TEXT
    DeployCommands.run_deploy
  else
    fail DeployError, 'User declined deploy!'
  end
end

###
# Wrapper for various method calls.
# Using a wrapper allows for simple testing (e.g. as calls can be stubbed).
class DeployCommands
  def self.output(message)
    puts message
  end

  def self.input
    STDIN.gets.strip
  end

  def self.git_status
    `git status -s`
  end

  def self.run_tests
    `rspec`
  end

  # Push from Github to Heroku
  def self.run_deploy
    `git push banksclosedtoday_heroku master`
  end
end
