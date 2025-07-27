require 'rails_helper'

RSpec.describe Follows::UnfollowService do
  let(:follower) { create(:user) }
  let(:followed) { create(:user) }
  let(:service) { described_class.new(follower: follower, followed_id: followed.id) }

  describe '#call!' do
    context 'when unfollowing a followed user' do
      before do
        create(:follow, follower: follower, followed: followed)
      end

      it 'removes the follow relationship' do
        result = service.call!
        
        aggregate_failures do
          expect(result.success?).to be true
          expect(follower.followed_users).not_to include(followed)
          expect(followed.followers).not_to include(follower)
        end
      end
    end

    context 'when trying to unfollow a user that not following' do
      it 'returns failure' do
        result = service.call!
        
        aggregate_failures do
          expect(result.success?).to be false
          expect(result.error).to eq('Follow relationship not found')
        end
      end
    end
  end
end 