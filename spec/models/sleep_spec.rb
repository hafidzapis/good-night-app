require 'rails_helper'

RSpec.describe Sleep, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:clock_in_time) }
    it { should validate_numericality_of(:duration_minutes).is_greater_than_or_equal_to(10).allow_nil }
  end

  describe 'scopes' do
    let!(:user) { create(:user) }
    let!(:active_sleep) { create(:sleep, :active, user: user) }
    let!(:completed_sleep) { create(:sleep, :completed, user: user) }

    describe '.active' do
      it 'returns only active sleep sessions' do
        expect(Sleep.active).to include(active_sleep)
        expect(Sleep.active).not_to include(completed_sleep)
      end
    end

    describe '.completed' do
      it 'returns only completed sleep sessions' do
        expect(Sleep.completed).to include(completed_sleep)
        expect(Sleep.completed).not_to include(active_sleep)
      end
    end
  end

  describe 'duration calculation' do
    let(:user) { create(:user) }
    let(:clock_in_time) { Time.zone.now - 8.hours }
    let(:clock_out_time) { Time.zone.now }

    it 'calculates duration when clock_out_time is set' do
      sleep = create(:sleep, user: user, clock_in_time: clock_in_time, clock_out_time: clock_out_time)
      
      expect(sleep.duration_minutes).to eq(480)
    end

    it 'does not calculate duration for active sleep' do
      sleep = create(:sleep, :active, user: user, clock_in_time: clock_in_time)
      
      expect(sleep.duration_minutes).to be_nil
    end

    it 'recalculates duration when clock_out_time changes' do
      sleep = create(:sleep, :active, user: user, clock_in_time: clock_in_time)
      
      sleep.update(clock_out_time: clock_out_time)
      
      expect(sleep.duration_minutes).to eq(480)
    end
  end

  describe 'business logic' do
    let(:user) { create(:user) }

    it 'cannot have sleep duration less than 10 minutes' do
      sleep = build(:sleep, 
        user: user, 
        clock_in_time: Time.zone.now, 
        clock_out_time: Time.zone.now + 5.minutes
      )
      
      expect(sleep).not_to be_valid
      expect(sleep.errors[:clock_out_time]).to include('sleep duration must be at least 10 minutes')
    end

    it 'allows sleep duration of exactly 10 minutes' do
      sleep = build(:sleep, 
        user: user, 
        clock_in_time: Time.zone.now, 
        clock_out_time: Time.zone.now + 10.minutes
      )
      
      expect(sleep).to be_valid
      expect(sleep.duration_minutes).to eq(10)
    end
  end
end 