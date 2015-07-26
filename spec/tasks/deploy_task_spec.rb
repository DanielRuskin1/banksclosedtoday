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
  DEPLOY_COMMANDS_METHODS_TO_STUB = [:output, :input, :current_path, :run_rubocop, :git_status, :run_tests, :run_deploy]
  before do
    # Make sure no additional methods have been introduced.
    # If any have been, they will need to be added to the above array (or this check will need to change).
    # Passing 'false' to this DeployCommands#methods hides any inherited methods (e.g. from Object).
    if DeployCommands.methods(false).sort != DEPLOY_COMMANDS_METHODS_TO_STUB.sort
      fail 'New DeployCommands methods found!  Please consider adding to DEPLOY_COMMANDS_METHODS_TO_STUB, or removing this check.'
    end

    # Stub all methods
    DEPLOY_COMMANDS_METHODS_TO_STUB.each do |method_name|
      allow(DeployCommands).to receive(method_name)
    end
  end

  # Helper method to run the task
  def run_rake_task
    Rake::Task['deploy'].reenable
    Rake.application.invoke_task('deploy')
  end

  context 'when the current path is not correct' do
    before do
      # Stub current_path to return an incorrect path
      allow(DeployCommands).to receive(:current_path).and_return('/Users/danielruskin/code/otherrepo')
    end

    it 'should fail the deploy' do
      # Run task and make sure it raises a DeployError
      expect do
        run_rake_task
      end.to raise_error(DeployError, 'You must be in the following path to deploy: /Users/danielruskin/code/banksclosedtoday.')

      # Make sure that the task got to the correct point
      expect(DeployCommands).to have_received(:current_path)
      expect(DeployCommands).to_not have_received(:run_rubocop)
      expect(DeployCommands).to_not have_received(:git_status)
      expect(DeployCommands).to_not have_received(:run_tests)
      expect(DeployCommands).to_not have_received(:input)
      expect(DeployCommands).to_not have_received(:run_deploy)
    end
  end

  context 'when the current path is correct' do
    before do
      # Stub current_path to return the correct path
      allow(DeployCommands).to receive(:current_path).and_return('/Users/danielruskin/code/banksclosedtoday')
    end

    context 'when rubocop fails' do
      ['16 files inspected, 1 offense detected', '16 files inspected, 2 offenses detected', 'no offense detected 16 files inspected, 1 offense detected'].each do |failure_result_string|
        it "should abort for #{failure_result_string}" do
          # Stub DeployCommands#run_rubocop to return the failure_result_string
          allow(DeployCommands).to receive(:run_rubocop).and_return(failure_result_string)

          # Run task and make sure it raises a DeployError
          expect do
            run_rake_task
          end.to raise_error(DeployError, 'Rubocop failed!')

          # Make sure that the task got to the correct point
          expect(DeployCommands).to have_received(:current_path)
          expect(DeployCommands).to have_received(:run_rubocop)
          expect(DeployCommands).to_not have_received(:git_status)
          expect(DeployCommands).to_not have_received(:run_tests)
          expect(DeployCommands).to_not have_received(:input)
          expect(DeployCommands).to_not have_received(:run_deploy)
        end
      end
    end

    context 'when rubocop passes' do
      before do
        # Stub run_rubocop to return a passed result
        allow(DeployCommands).to receive(:run_rubocop).and_return('16 files inspected, no offenses detected')
      end

      context 'when uncommited changes are present' do
        before do
          # Stub git_status to return uncommited changes
          allow(DeployCommands).to receive(:git_status).and_return('M lib/tasks/deploy.rake')
        end

        it 'should fail the deploy' do
          # Run task and make sure it raises a DeployError
          expect do
            run_rake_task
          end.to raise_error(DeployError, 'Please commit changes before deploying.')

          # Make sure that the task got to the correct point
          expect(DeployCommands).to have_received(:current_path)
          expect(DeployCommands).to have_received(:run_rubocop)
          expect(DeployCommands).to have_received(:git_status)
          expect(DeployCommands).to_not have_received(:run_tests)
          expect(DeployCommands).to_not have_received(:input)
          expect(DeployCommands).to_not have_received(:run_deploy)
        end
      end

      context 'when no uncommited changes are present' do
        before do
          # Stub git_status to return no uncommited changes
          allow(DeployCommands).to receive(:git_status).and_return('')
        end

        context 'when tests fail' do
          ['2392 examples, 111 failures', '35 examples, 10 failures', '20 examples, 1 failure', 'WeirdSample'].each do |failure_result_string|
            it "should abort for #{failure_result_string}" do
              # Stub run_tests to return the relevant failure result string
              allow(DeployCommands).to receive(:run_tests).and_return(failure_result_string)

              # Run task and make sure it raises a DeployError
              expect do
                run_rake_task
              end.to raise_error(DeployError, 'Tests did not pass!')

              # Make sure that the task got to the correct point
              expect(DeployCommands).to have_received(:current_path)
              expect(DeployCommands).to have_received(:run_rubocop)
              expect(DeployCommands).to have_received(:git_status)
              expect(DeployCommands).to have_received(:run_tests)
              expect(DeployCommands).to_not have_received(:input)
              expect(DeployCommands).to_not have_received(:run_deploy)
            end
          end
        end

        context 'when tests pass' do
          before do
            # Stub run_tests to return a success
            allow(DeployCommands).to receive(:run_tests).and_return('35 examples, 0 failures')
          end

          context 'when the user declines the deploy' do
            %w(deploy decline DECLINE).each do |decline_string|
              it "should abort for #{decline_string}" do
                # Stub DeployCommands#input to return the decline string
                allow(DeployCommands).to receive(:input).and_return(decline_string)

                # Run task and make sure it raises a DeployError
                expect do
                  run_rake_task
                end.to raise_error(DeployError, 'User declined deploy!')

                # Make sure that the task got to the correct point
                expect(DeployCommands).to have_received(:current_path)
                expect(DeployCommands).to have_received(:run_rubocop)
                expect(DeployCommands).to have_received(:git_status)
                expect(DeployCommands).to have_received(:run_tests)
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

            it 'should deploy' do
              # Run task
              run_rake_task

              # Make sure that the task got to the correct point
              expect(DeployCommands).to have_received(:current_path)
              expect(DeployCommands).to have_received(:run_rubocop)
              expect(DeployCommands).to have_received(:git_status)
              expect(DeployCommands).to have_received(:run_tests)
              expect(DeployCommands).to have_received(:input)
              expect(DeployCommands).to have_received(:run_deploy)
            end
          end
        end
      end
    end
  end
end
