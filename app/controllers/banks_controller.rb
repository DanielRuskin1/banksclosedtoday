class BanksController < ApplicationController
  def index
    raise "foo"
    @bank_status = BankService.bank_status(DateTime.now.in_time_zone)
  end
end
