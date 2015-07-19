require 'spec_helper'

describe 'Bank' do
  context "unimplemented methods" do
    ["schedule_name", "schedule_link", "time_to_check", "applicable_holiday_regions", "observed_holidays", "bank_closure_reason"].each do |method_name|
      describe "##{method_name}" do
        it "should raise a NotImplementedError" do
          expect {
            Bank.send(method_name)
          }.to raise_error(NotImplementedError)
        end
      end
    end
  end
end
