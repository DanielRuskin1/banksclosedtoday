class BanksController < ApplicationController
  def index
    @bank_status = BankService.bank_status(DateTime.now)
  end
end
