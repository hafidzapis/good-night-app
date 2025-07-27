require 'rails_helper'

RSpec.describe Sleeps::ClockOutService do
  let(:user) { create(:user) }
  let(:sleep_record) { create(:sleep, :active, user: user, clock_in_time: 1.hour.ago) }
  let(:service) { described_class.new(user: user, sleep_record_id: sleep_record.id) }

  describe '#call!' do
    context 'when sleep record exists and is active' do
      it 'updates the sleep record with clock out time' do
        Timecop.freeze do
          result = service.call!

          expect(result.success?).to be true
          expect(result.data.clock_out_time).to be_within(1.second).of(Time.zone.now)
          expect(result.data.duration_minutes).to be_present
          expect(result.data.duration_minutes).to be > 0
        end
      end

      it 'calculates duration correctly' do
        clock_in_time = 2.hours.ago
        sleep_record.update!(clock_in_time: clock_in_time)
        
        Timecop.freeze do
          result = service.call!
          
          expected_duration = ((Time.zone.now - clock_in_time) / 60).to_i
          expect(result.data.duration_minutes).to eq(expected_duration)
        end
      end
    end

    context 'when sleep record is already clocked out' do
      before do
        sleep_record.update!(clock_out_time: 30.minutes.ago)
      end

      it 'returns failure' do
        result = service.call!

        expect(result.failure?).to be true
        expect(result.error).to eq('Sleep record has already been clocked out')
      end

      it 'does not update the clock out time' do
        original_clock_out_time = sleep_record.clock_out_time
        
        service.call!
        
        sleep_record.reload
        expect(sleep_record.clock_out_time).to eq(original_clock_out_time)
      end
    end

    context 'when sleep record does not exist' do
      let(:service) { described_class.new(user: user, sleep_record_id: 999) }

      it 'returns failure' do
        result = service.call!

        expect(result.failure?).to be true
        expect(result.error).to eq('Sleep record not found')
      end
    end

    context 'when sleep record belongs to different user' do
      let(:other_user) { create(:user) }
      let(:other_sleep_record) { create(:sleep, :active, user: other_user) }
      let(:service) { described_class.new(user: user, sleep_record_id: other_sleep_record.id) }

      it 'returns failure' do
        result = service.call!

        expect(result.failure?).to be true
        expect(result.error).to eq('Sleep record not found')
      end
    end
  end
end 