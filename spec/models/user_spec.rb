require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:sleeps).dependent(:destroy) }
    it { should have_many(:follows).with_foreign_key(:follower_id).class_name('Follow').dependent(:destroy) }
    it { should have_many(:followed_users).through(:follows).source(:followed) }
    it { should have_many(:reverse_follows).with_foreign_key(:followed_id).class_name('Follow').dependent(:destroy) }
    it { should have_many(:followers).through(:reverse_follows).source(:follower) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
  end

  describe 'follow relationships' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    it 'can follow another user' do
      follow = create(:follow, follower: user1, followed: user2)
      expect(user1.followed_users).to include(user2)
      expect(user2.followers).to include(user1)
    end

    it 'cannot follow itself' do
      follow = build(:follow, follower: user1, followed: user1)
      expect(follow).not_to be_valid
      expect(follow.errors[:base]).to include('Cannot follow yourself')
    end
  end
end 