require 'rails_helper'

RSpec.describe Sleeps::ClockInService do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user: user) }

  describe '#call!' do
    context 'when user has no active sleep record' do
      it 'creates a new sleep record' do
        expect {
          result = service.call!
          expect(result.success?).to be true
          expect(result.data[:sleep_record]).to be_present
          expect(result.data[:sleep_record].clock_in_time).to be_present
          expect(result.data[:sleep_record].clock_out_time).to be_nil
        }.to change(Sleep, :count).by(1)
      end

      it 'sets the clock_in_time to current time' do
        Timecop.freeze do
          result = service.call!
          expect(result.data[:sleep_record].clock_in_time).to be_within(1.second).of(Time.zone.now)
        end
      end
    end

    context 'when user already has an active sleep record' do
      before do
        create(:sleep, :active, user: user)
      end

      it 'returns failure' do
        result = service.call!

        expect(result.failure?).to be true
        expect(result.error).to eq('User already has an active sleep record')
      end

      it 'does not create a new sleep record' do
        expect {
          service.call!
        }.not_to change(Sleep, :count)
      end
    end

    context 'when sleep record creation fails' do
      before do
        allow(user.sleeps).to receive(:build).and_return(invalid_sleep)
      end

      let(:invalid_sleep) do
        sleep_record = build(:sleep, user: user)
        sleep_record.errors.add(:base, 'Some validation error')
        allow(sleep_record).to receive(:save).and_return(false)
        allow(sleep_record).to receive(:errors).and_return(double(full_messages: ['Some validation error']))
        sleep_record
      end

      it 'returns failure with error messages' do
        result = service.call!

        expect(result.failure?).to be true
        expect(result.error).to include('Some validation error')
      end
    end
  end
end 