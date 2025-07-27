require 'rails_helper'

RSpec.describe Follows::FollowService do
  let(:follower) { create(:user) }
  let(:followed) { create(:user) }
  let(:service) { described_class.new(follower: follower, followed_id: followed.id) }

  describe '#call!' do
    context 'when following a valid user' do
      it 'creates a follow relationship' do
        result = service.call!
        
        aggregate_failures do
          expect(result.success?).to be true
          expect(follower.followed_users).to include(followed)
          expect(followed.followers).to include(follower)
        end
      end
    end

    context 'when trying to follow yourself' do
      let(:service) { described_class.new(follower: follower, followed_id: follower.id) }

      it 'returns failure' do
        result = service.call!
        
        aggregate_failures do
          expect(result.success?).to be false
          expect(result.error).to eq('Cannot follow yourself')
        end
      end
    end

    context 'when trying to follow a non-existent user' do
      let(:service) { described_class.new(follower: follower, followed_id: 99999) }

      it 'returns failure' do
        result = service.call!
        
        aggregate_failures do
          expect(result.success?).to be false
          expect(result.error).to eq('User not found')
        end
      end
    end

    context 'when already following the user' do
      before do
        create(:follow, follower: follower, followed: followed)
      end

      it 'returns failure' do
        result = service.call!
        aggregate_failures do
          expect(result.success?).to be false
          expect(result.error).to include('is already following this user')
        end
      end
    end
  end
end 