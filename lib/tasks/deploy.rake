# Env variables that are required for a deploy to take place
# DEPLOY_ORIGINATION_PATH - The path that you will start deploys from (e.g. /Users/MyUsername/code/banksclosedtoday)
# HEROKU_SUCCESS_MESSAGE - The message that will be considered representative of a successful deploy
# HEROKU_REMOTE_NAME - The name of the git remote that represents your Heroku application
# These should be set in the .ENV file - not in prod!
REQUIRED_ENV_VARIABLES = %w(DEPLOY_ORIGINATION_PATH HEROKU_SUCCESS_MESSAGE HEROKU_REMOTE_NAME)

# Correct path for deploys to take place in
CORRECT_DEPLOY_PATH = ENV['DEPLOY_ORIGINATION_PATH']

# Test regex constants
TESTS_FAILED_REGEX = /, [^0].* failure/ # If this matches, the task will assume that tests failed
TESTS_PASSED_REGEX = /, 0 failures/

# Rubocop regex constants
RUBOCOP_FAILED_REGEX = /, [^no].* offense/
RUBOCOP_PASSED_REGEX = /, no offenses detected/

# Deploy constants
ACCEPT_DEPLOY_TEXT = 'DEPLOY'
DEPLOY_FAILED_STRING = 'Push rejected'
DEPLOY_PASSED_STRING = ENV['HEROKU_SUCCESS_MESSAGE']

# Error class for exceptions that can occur during a deploy attempt
class DeployError < StandardError; end

task :deploy do
  # Make sure that the current environment is eligible for a deploy
  check_environment

  # Make sure that all required env variables are set
  # If are any are not present, a deploy is not possible
  # (e.g. since we might not know where to deploy to, or what constitutes a success)
  check_env_variables

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

  # Complete the deploy
  complete_deploy
end

###
# Helper method for:
# 1. Checking whether the current env is production
# 2. Failing if so
def check_environment
  fail DeployError, 'You cannot deploy from the production environment!'.red if DeployCommands.rails_environment.production?
end

###
# Helper method for:
# 1. Checking whether all required env variables are present
# 2. Failing if not
def check_env_variables
  REQUIRED_ENV_VARIABLES.each do |required_env_variable|
    fail DeployError, "Env variable #{required_env_variable} is not present!".red unless DeployCommands.get_env_variable(required_env_variable)
  end
end

###
# Helper method for:
# 1. Checking the current path, and
# 2. Raising an exception if it is not correct
def check_current_path
  # Log
  DeployCommands.output('Checking path...'.yellow)

  # Fail if path is incorrect
  if DeployCommands.current_path != CORRECT_DEPLOY_PATH
    # Abort
    fail DeployError, "You must be in the following path to deploy: #{CORRECT_DEPLOY_PATH}.".red
  else
    # Log
    DeployCommands.output('Path OK!'.green)
  end
end

###
# Helper method for:
# 1. Running rubocop on the repo,
# 2. Raising an exception if any offenses are detected
def check_rubocop
  # Log
  DeployCommands.output('Running rubocop...'.yellow)

  # Run rubocop and output result
  rubocop_result = DeployCommands.run_rubocop
  DeployCommands.output(rubocop_result)

  # Fail deploy if the fail regex matches, or the pass regex does not match
  if rubocop_result.match(RUBOCOP_FAILED_REGEX) || !rubocop_result.match(RUBOCOP_PASSED_REGEX)
    # Abort
    fail DeployError, 'Rubocop failed!'.red
  else
    # Log
    DeployCommands.output('Rubocop passed!'.green)
  end
end

###
# Helper method for:
# 1. Running tests and outputting the results, and
# 2. Raising an exception if any tests failed.
def run_and_verify_tests
  # Log
  DeployCommands.output('Running tests...'.yellow)

  # Run tests and output result
  test_result = DeployCommands.run_tests
  DeployCommands.output(test_result)

  # Fail deploy if the fail regex matches, or the pass regex does not match
  if test_result.match(TESTS_FAILED_REGEX) || !test_result.match(TESTS_PASSED_REGEX)
    # Abort
    fail DeployError, 'Tests did not pass!'.red
  else
    # Log
    DeployCommands.output('Tests passed!'.green)
  end
end

###
# Helper method for:
# 1. Checking whether any uncommitted changes are present in git, and
# 2. Raising an exception if so.
def check_for_uncommitted_changes
  # Log
  DeployCommands.output('Checking for uncommitted changes...'.yellow)

  # git_status will return a list of any modified/uncommitted files.
  if DeployCommands.git_status.present?
    # Abort
    fail DeployError, 'Please commit changes before deploying.'.red
  else
    # Log
    DeployCommands.output('No uncommitted changes!'.green)
  end
end

###
# Helper method for:
# 1. Prompting the user to complete the deploy,
# 2. Raising an exception if they do not accept with the correct string.
def prompt_user_to_complete_deploy
  # Prompt user to accept deploy
  DeployCommands.output("Please review any output above, then type #{ACCEPT_DEPLOY_TEXT} to start the deploy.")

  # If the user accepts the deploy, deploy.
  # Otherwise, abort.
  if DeployCommands.input != ACCEPT_DEPLOY_TEXT
    # Abort
    fail DeployError, 'User declined deploy!'.red
  else
    # Log
    DeployCommands.output('User accepted deploy!'.green)
  end
end

def complete_deploy
  # Log
  DeployCommands.output('Completing deploy...'.green)

  # Deploy and output result
  deploy_result = DeployCommands.run_deploy
  DeployCommands.output(deploy_result)

  # Check if deploy was successful, then fail/output as necessary
  if deploy_result.include?(DEPLOY_FAILED_STRING) || !deploy_result.include?(DEPLOY_PASSED_STRING)
    fail DeployError, 'Deploy failed!'.red
  else
    # Log
    DeployCommands.output('Deploy completed!'.green)
  end
end

###
# Wrapper for various method calls.
# Using a wrapper allows for simple testing (e.g. as calls can be stubbed).
# 2>&1 is used for commands that need to recognize stderr output;
# it redirects stderr to stdout (which ruby recognizes).
class DeployCommands
  def self.output(message)
    puts message
  end

  def self.input
    STDIN.gets.strip
  end

  def self.rails_environment
    Rails.env
  end

  def self.get_env_variable(variable_name)
    ENV[variable_name]
  end

  def self.current_path
    Dir.pwd
  end

  def self.run_rubocop
    `rubocop`
  end

  def self.git_status
    `git status -s 2>&1`
  end

  def self.run_tests
    `rspec`
  end

  def self.run_deploy
    `git push #{ENV['HEROKU_REMOTE_NAME']} master 2>&1`
  end
end
