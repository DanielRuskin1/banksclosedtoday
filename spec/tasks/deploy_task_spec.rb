require 'spec_helper'
require 'rake'

describe 'deploy task' do
  before(:all) do
    # Load deploy task
    Rake.application.rake_require('tasks/deploy')
  end

  before do
    # Stub all DeployCommands calls
    # These are also stubbed later on, but we need to be 100% sure that these are never actually run.
    # Doing so could have unintended consequences (e.g. actually triggering a deploy).
    allow(DeployCommands).to receive(:output) # Actual output will interfere with deploys
    allow(DeployCommands).to receive(:input)
    allow(DeployCommands).to receive(:git_status)
    allow(DeployCommands).to receive(:run_tests)
    allow(DeployCommands).to receive(:run_deploy)
  end

  # Helper method to run the task
  def run_rake_task
    Rake::Task['deploy'].reenable
    Rake.application.invoke_task('deploy')
  end

  context "when uncommited changes are present" do
    before do
      # Stub check_for_uncommited_changes to return uncommited changes
      allow(DeployCommands).to receive(:git_status).and_return("M lib/tasks/deploy.rake")
    end

    it "should fail the deploy" do
      # Run task and make sure it raises a DeployError
      expect do
        run_rake_task
      end.to raise_error(DeployError, 'Please commit changes before deploying.')

      # Make sure that
      # 1. DeployCommands#check_for_uncommited_changes was called,
      # 2. DeployCommands#run_tests was not called,
      # 3. DeployCommands#input was not called,
      # 4. DeployCommands#run_deploy was not called
      expect(DeployCommands).to have_received(:git_status)
      expect(DeployCommands).to_not have_received(:run_tests)
      expect(DeployCommands).to_not have_received(:input)
      expect(DeployCommands).to_not have_received(:run_deploy)
    end
  end

  context "when no uncommited changes are present" do
    before do
      # Stub check_for_uncommited_changes to return no uncommited changes
      allow(DeployCommands).to receive(:git_status).and_return("")
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

          # Make sure that
          # 1. DeployCommands#check_for_uncommited_changes was called,
          # 2. DeployCommands#run_tests was called,
          # 3. DeployCommands#input was not called,
          # 4. DeployCommands#run_deploy was not called
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

            # Make sure that
            # 1. DeployCommands#check_for_uncommited_changes was called,
            # 2. DeployCommands#run_tests was called,
            # 3. DeployCommands#input was called,
            # 4. DeployCommands#run_deploy was not called
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

          # Make sure that
          # 1. DeployCommands#check_for_uncommited_changes was called,
          # 2. DeployCommands#run_tests was called,
          # 3. DeployCommands#input was called,
          # 4. DeployCommands#run_deploy was called
          expect(DeployCommands).to have_received(:git_status)
          expect(DeployCommands).to have_received(:run_tests)
          expect(DeployCommands).to have_received(:input)
          expect(DeployCommands).to have_received(:run_deploy)
        end
      end
    end
  end
end
