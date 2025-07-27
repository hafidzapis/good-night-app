require 'rails_helper'

RSpec.describe UserSleepSummaryJob, type: :job do
  let(:user) { create(:user) }
  let(:date) { Date.current }

  describe '#perform' do
    it 'calls the service with correct parameters' do
      expect(Sleeps::SleepSummaryPopulatorService).to receive(:new).with(
        user: user,
        date: date
      ).and_return(double(call!: double(success?: true, data: nil)))

      UserSleepSummaryJob.perform_now(user.id, date)
    end
  end
end 