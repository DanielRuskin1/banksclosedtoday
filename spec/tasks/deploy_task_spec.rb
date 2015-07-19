require 'spec_helper'
require 'rake'

describe 'deploy task' do
  before(:all) do
    # Load deploy task
    Rake.application.rake_require('tasks/deploy')
  end

  before do
    # Stub run_deploy call
    # We don't want to actually have the method run, as doing so would trigger a deploy.
    allow(DeployCommands).to receive(:run_deploy)

    # Stub puts call
    # There's no need to actually puts here - doing so could interfere with actual deploys.
    # (e.g. as output from "when tests fail" tests could lead to a deploy being aborted)
    allow(DeployCommands).to receive(:output)
  end

  # Helper method to run the task
  def run_rake_task
    Rake::Task['deploy'].reenable
    Rake.application.invoke_task('deploy')
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
        # 1. DeployCommands.run_tests was called,
        # 2. DeployCommands.run_deploy was not called
        expect(DeployCommands).to have_received(:run_tests)
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
          # Stub STDIN.gets to return the decline string
          allow(STDIN).to receive(:gets).and_return(decline_string)

          # Run task and make sure it raises a DeployError
          expect do
            run_rake_task
          end.to raise_error(DeployError, 'User declined deploy!')

          # Make sure that
          # 1. DeployCommands.run_tests was called,
          # 2. STDIN.gets was called,
          # 3. DeployCommands.run_deploy was not called
          expect(DeployCommands).to have_received(:run_tests)
          expect(STDIN).to have_received(:gets)
          expect(DeployCommands).to_not have_received(:run_deploy)
        end
      end
    end

    context 'when the user accepts the deploy' do
      before do
        # Stub STDIN.gets to return the accept string
        allow(STDIN).to receive(:gets).and_return('DEPLOY')
      end

      it 'should deploy' do
        # Run task
        run_rake_task

        # Make sure that
        # 1. DeployCommands.run_tests was called,
        # 2. STDIN.gets was called,
        # 3. DeployCommands.run_deploy was called
        expect(DeployCommands).to have_received(:run_tests)
        expect(STDIN).to have_received(:gets)
        expect(DeployCommands).to have_received(:run_deploy)
      end
    end
  end
end
