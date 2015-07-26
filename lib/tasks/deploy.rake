# Correct path for deploys to take place in
CORRECT_DEPLOY_PATH = '/Users/danielruskin/code/banksclosedtoday'

# Test regex constants
TESTS_FAILED_REGEX = /, [^0].* failure/ # If this matches, the task will assume that tests failed
TESTS_PASSED_REGEX = /, 0 failures/

# Rubocop regex constants
RUBOCOP_FAILED_REGEX = /, [^no].* offense/
RUBOCOP_PASSED_REGEX = /, no offenses detected/

# General deploy constants
ACCEPT_DEPLOY_TEXT = 'DEPLOY'

# Error class for exceptions that can occur during a deploy attempt
class DeployError < StandardError; end

task :deploy do
  # Check current path
  check_current_path

  # Check rubocop
  check_rubocop

  # Run/verify tests
  run_and_verify_tests

  # Check for uncommitted changes
  check_for_uncommitted_changes

  # Prompt user to accept deploy
  prompt_user_to_complete_deploy
end

###
# Helper method for:
# 1. Checking the current path, and
# 2. Raising an exception if it is not correct
def check_current_path
  # Fail if path is incorrect
  fail DeployError, "You must be in the following path to deploy: #{CORRECT_DEPLOY_PATH}." if DeployCommands.current_path != CORRECT_DEPLOY_PATH
end

###
# Helper method for:
# 1. Running rubocop on the repo,
# 2. Raising an exception if any offenses are detected
def check_rubocop
  # Run rubocop
  rubocop_result = DeployCommands.run_rubocop

  # Fail deploy if the fail regex matches, or the pass regex does not match
  fail DeployError, 'Rubocop failed!' if rubocop_result.match(RUBOCOP_FAILED_REGEX) || !rubocop_result.match(RUBOCOP_PASSED_REGEX)
end

###
# Helper method for:
# 1. Running tests and outputting the results, and
# 2. Raising an exception if any tests failed.
def run_and_verify_tests
  # Run tests and output result
  test_result = DeployCommands.run_tests
  DeployCommands.output(test_result)

  # Fail deploy if the fail regex matches, or the pass regex does not match
  fail DeployError, 'Tests did not pass!' if test_result.match(TESTS_FAILED_REGEX) || !test_result.match(TESTS_PASSED_REGEX)
end

###
# Helper method for:
# 1. Checking whether any uncommitted changes are present in git, and
# 2. Raising an exception if so.
def check_for_uncommitted_changes
  # git_status will return a list of any modified/uncommitted files.
  fail DeployError, 'Please commit changes before deploying.' if DeployCommands.git_status.present?
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

  def self.current_path
    Dir.pwd
  end

  def self.run_rubocop
    `rubocop`
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
