class BanksController < ApplicationController
  def index
    @bank_status = BankService.bank_status(DateTime.now.in_time_zone)
  end
end
