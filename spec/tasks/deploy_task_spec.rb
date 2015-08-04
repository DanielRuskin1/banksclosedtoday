require 'spec_helper'
require 'rake'

describe 'deploy task' do
  before(:all) do
    # Load deploy task
    Rake.application.rake_require('tasks/deploy')
  end

  # List of methods to stub on DeployCommands.
  # These are also stubbed later on, but we need to be 100% sure that these are never actually run.
  # Doing so could have unintended consequences (e.g. actually triggering a deploy, or interfering with a deploy that runs tests).
  DEPLOY_COMMANDS_METHODS_TO_STUB = [:output, :input, :rails_environment, :get_env_variable, :current_path, :run_rubocop, :git_status, :run_tests, :run_deploy]
  before do
    # Make sure no additional methods have been introduced.
    # If any have been, they will need to be added to the above array (or this check will need to change).
    # Passing 'false' to this DeployCommands#methods hides any inherited methods (e.g. from Object).
    if DeployCommands.methods(false).sort != DEPLOY_COMMANDS_METHODS_TO_STUB.sort
      fail 'New DeployCommands methods found!  Please consider adding to DEPLOY_COMMANDS_METHODS_TO_STUB, or removing this check.'
    end

    # Make sure that no instance_methods are present
    # False serves the same purpose here (hiding any inherited methods)
    if DeployCommands.instance_methods(false).any?
      fail 'Instance methods are present on DeployCommands!  Please remove them, or add code to stub them.'
    end

    # Stub methods defined in array
    DEPLOY_COMMANDS_METHODS_TO_STUB.each do |method_name|
      allow(DeployCommands).to receive(method_name)
    end
  end

  # Helper method to run the task
  def run_rake_task
    Rake::Task['deploy'].reenable
    Rake.application.invoke_task('deploy')
  end

  context "when the environment is production" do
    before do
      # Stub DeployCommands#current_path to return production
      allow(DeployCommands).to receive(:rails_environment).and_return(ActiveSupport::StringInquirer.new("production"))
    end

    it "should fail the deploy" do
      # Run task and make sure it raises a DeployError
      expect do
        run_rake_task
      end.to raise_error(DeployError, 'You cannot deploy from the production environment!'.red)

      # Make sure that the task got to the correct point
      expect(DeployCommands).to have_received(:rails_environment)
      expect(DeployCommands).to_not have_received(:get_env_variable)
      expect(DeployCommands).to_not have_received(:current_path)
      expect(DeployCommands).to_not have_received(:run_rubocop)
      expect(DeployCommands).to_not have_received(:run_tests)
      expect(DeployCommands).to_not have_received(:git_status)
      expect(DeployCommands).to_not have_received(:input)
      expect(DeployCommands).to_not have_received(:run_deploy)
    end
  end

  context "when the environment is not production" do
    before do
      # Stub DeployCommands#current_path to return test
      allow(DeployCommands).to receive(:rails_environment).and_return(ActiveSupport::StringInquirer.new("test"))
    end

    context "when any ENV variables are not present" do
      it "should fail the deploy" do
        REQUIRED_ENV_VARIABLES.each do |missing_variable_name|
          # Stub DeployCommands#get_env_variable to return nothing
          # (e.g. to simulate a missing env variable)
          allow(DeployCommands).to receive(:get_env_variable).with(missing_variable_name).and_return(nil)

          # Run task and make sure it raises a DeployError
          expect do
            run_rake_task
          end.to raise_error(DeployError, "Env variable #{missing_variable_name} is not present!".red)

          # Make sure that the task got to the correct point
          expect(DeployCommands).to have_received(:rails_environment).at_least(:once)
          expect(DeployCommands).to have_received(:get_env_variable).at_least(:once)
          expect(DeployCommands).to_not have_received(:current_path)
          expect(DeployCommands).to_not have_received(:run_rubocop)
          expect(DeployCommands).to_not have_received(:run_tests)
          expect(DeployCommands).to_not have_received(:git_status)
          expect(DeployCommands).to_not have_received(:input)
          expect(DeployCommands).to_not have_received(:run_deploy)

          # Re-stub with the actual value (so the next test can get past it)
          allow(DeployCommands).to receive(:get_env_variable).with(missing_variable_name).and_return(ENV[missing_variable_name])
        end
      end
    end

    context "when all ENV variables are present" do
      before do
        # Stub DeployCommands#current_path to return all required env variables
        # set in this environment.
        REQUIRED_ENV_VARIABLES.each do |available_variable_name|
          allow(DeployCommands).to receive(:get_env_variable).with(available_variable_name).and_return(ENV[available_variable_name])
        end
      end

      context 'when the current path is not correct' do
        before do
          # Stub DeployCommands#current_path to return an incorrect path
          allow(DeployCommands).to receive(:current_path).and_return('/Users/danielruskin/code/otherrepo')
        end

        it 'should fail the deploy' do
          # Run task and make sure it raises a DeployError
          expect do
            run_rake_task
          end.to raise_error(DeployError, 'You must be in the following path to deploy: /Users/danielruskin/code/banksclosedtoday.'.red)

          # Make sure that the task got to the correct point
          expect(DeployCommands).to have_received(:rails_environment)
          expect(DeployCommands).to have_received(:get_env_variable).at_least(:once)
          expect(DeployCommands).to have_received(:current_path)
          expect(DeployCommands).to_not have_received(:run_rubocop)
          expect(DeployCommands).to_not have_received(:run_tests)
          expect(DeployCommands).to_not have_received(:git_status)
          expect(DeployCommands).to_not have_received(:input)
          expect(DeployCommands).to_not have_received(:run_deploy)
        end
      end

      context 'when the current path is correct' do
        before do
          # Stub DeployCommands#current_path to return the correct path
          allow(DeployCommands).to receive(:current_path).and_return('/Users/danielruskin/code/banksclosedtoday')
        end

        context 'when rubocop fails' do
          ['16 files inspected, 1 offense detected', '16 files inspected, 2 offenses detected', 'no offenses detected 16 files inspected, 1 offense detected'].each do |failure_result_string|
            it "should abort for #{failure_result_string}" do
              # Stub DeployCommands#run_rubocop to return the failure_result_string
              allow(DeployCommands).to receive(:run_rubocop).and_return(failure_result_string)

              # Run task and make sure it raises a DeployError
              expect do
                run_rake_task
              end.to raise_error(DeployError, 'Rubocop failed!'.red)

              # Make sure that the task got to the correct point
              expect(DeployCommands).to have_received(:rails_environment)
              expect(DeployCommands).to have_received(:get_env_variable).at_least(:once)
              expect(DeployCommands).to have_received(:current_path)
              expect(DeployCommands).to have_received(:run_rubocop)
              expect(DeployCommands).to_not have_received(:run_tests)
              expect(DeployCommands).to_not have_received(:git_status)
              expect(DeployCommands).to_not have_received(:input)
              expect(DeployCommands).to_not have_received(:run_deploy)
            end
          end
        end

        context 'when rubocop passes' do
          before do
            # Stub DeployCommands#run_rubocop to return a passed result
            allow(DeployCommands).to receive(:run_rubocop).and_return('16 files inspected, no offenses detected')
          end

          context 'when tests fail' do
            ['2392 examples, 111 failures', '35 examples, 10 failures', '20 examples, 1 failure', '20 examples, 0 failures, 20 examples, 2 failures', 'WeirdSample'].each do |failure_result_string|
              it "should abort for #{failure_result_string}" do
                # Stub DeployCommands#run_tests to return the relevant failure result string
                allow(DeployCommands).to receive(:run_tests).and_return(failure_result_string)

                # Run task and make sure it raises a DeployError
                expect do
                  run_rake_task
                end.to raise_error(DeployError, 'Tests did not pass!'.red)

                # Make sure that the task got to the correct point
                expect(DeployCommands).to have_received(:rails_environment)
                expect(DeployCommands).to have_received(:get_env_variable).at_least(:once)
                expect(DeployCommands).to have_received(:current_path)
                expect(DeployCommands).to have_received(:run_rubocop)
                expect(DeployCommands).to have_received(:run_tests)
                expect(DeployCommands).to_not have_received(:git_status)
                expect(DeployCommands).to_not have_received(:input)
                expect(DeployCommands).to_not have_received(:run_deploy)
              end
            end
          end

          context 'when tests pass' do
            before do
              # Stub DeployCommands#run_tests to return a success
              allow(DeployCommands).to receive(:run_tests).and_return('35 examples, 0 failures')
            end

            context 'when uncommitted changes are present' do
              before do
                # Stub DeployCommands#git_status to return uncommitted changes
                allow(DeployCommands).to receive(:git_status).and_return('M lib/tasks/deploy.rake')
              end

              it 'should fail the deploy' do
                # Run task and make sure it raises a DeployError
                expect do
                  run_rake_task
                end.to raise_error(DeployError, 'Please commit changes before deploying.'.red)

                # Make sure that the task got to the correct point
                expect(DeployCommands).to have_received(:rails_environment)
                expect(DeployCommands).to have_received(:get_env_variable).at_least(:once)
                expect(DeployCommands).to have_received(:current_path)
                expect(DeployCommands).to have_received(:run_rubocop)
                expect(DeployCommands).to have_received(:run_tests)
                expect(DeployCommands).to have_received(:git_status)
                expect(DeployCommands).to_not have_received(:input)
                expect(DeployCommands).to_not have_received(:run_deploy)
              end
            end

            context 'when no uncommitted changes are present' do
              before do
                # Stub DeployCommands#git_status to return no uncommitted changes
                allow(DeployCommands).to receive(:git_status).and_return('')
              end

              context 'when the user declines the deploy' do
                %w(deploy decline DECLINE).each do |decline_string|
                  it "should abort for #{decline_string}" do
                    # Stub DeployCommands#input to return the decline string
                    allow(DeployCommands).to receive(:input).and_return(decline_string)

                    # Run task and make sure it raises a DeployError
                    expect do
                      run_rake_task
                    end.to raise_error(DeployError, 'User declined deploy!'.red)

                    # Make sure that the task got to the correct point
                    expect(DeployCommands).to have_received(:rails_environment)
                    expect(DeployCommands).to have_received(:get_env_variable).at_least(:once)
                    expect(DeployCommands).to have_received(:current_path)
                    expect(DeployCommands).to have_received(:run_rubocop)
                    expect(DeployCommands).to have_received(:run_tests)
                    expect(DeployCommands).to have_received(:git_status)
                    expect(DeployCommands).to have_received(:input)
                    expect(DeployCommands).to_not have_received(:run_deploy)
                  end
                end
              end

              context 'when the user accepts the deploy' do
                before do
                  # Stub DeployCommands#input to return the accept string
                  allow(DeployCommands).to receive(:input).and_return('DEPLOY')
                end

                context 'when the deploy fails' do
                  ['https://banksclosedtoday.herokuapp.com/ deployed to Heroku Push rejected', 'Push rejected!'].each do |failure_string|
                    it "should abort for #{failure_string}" do
                      # Stub DeployCommands#deploy to return the failure string
                      allow(DeployCommands).to receive(:run_deploy).and_return(failure_string)

                      # Run task and make sure it raises a DeployError
                      expect do
                        run_rake_task
                      end.to raise_error(DeployError, 'Deploy failed!'.red)

                      # Make sure that the task got to the correct point
                      expect(DeployCommands).to have_received(:rails_environment)
                      expect(DeployCommands).to have_received(:get_env_variable).at_least(:once)
                      expect(DeployCommands).to have_received(:current_path)
                      expect(DeployCommands).to have_received(:run_rubocop)
                      expect(DeployCommands).to have_received(:run_tests)
                      expect(DeployCommands).to have_received(:git_status)
                      expect(DeployCommands).to have_received(:input)
                      expect(DeployCommands).to have_received(:run_deploy)
                    end
                  end
                end

                context 'when the deploy succeeds' do
                  before do
                    # Stub DeployCommands#run_deploy to return the deploy success string
                    allow(DeployCommands).to receive(:run_deploy).and_return('https://banksclosedtoday.herokuapp.com/ deployed to Heroku')
                  end

                  it 'should not raise an error' do
                    # Run task
                    run_rake_task

                    # Make sure that the task got to the correct point
                    expect(DeployCommands).to have_received(:rails_environment)
                    expect(DeployCommands).to have_received(:get_env_variable).at_least(:once)
                    expect(DeployCommands).to have_received(:current_path)
                    expect(DeployCommands).to have_received(:run_rubocop)
                    expect(DeployCommands).to have_received(:run_tests)
                    expect(DeployCommands).to have_received(:git_status)
                    expect(DeployCommands).to have_received(:input)
                    expect(DeployCommands).to have_received(:run_deploy)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
