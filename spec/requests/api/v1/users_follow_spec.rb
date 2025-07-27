require 'rails_helper'

RSpec.describe 'Users Follow API', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:headers) { { 'Authorization' => user.name } }

  describe 'POST /api/v1/users/:id/follow' do
    context 'when following a valid user' do
      it 'creates a follow relationship' do
        post "/api/v1/users/#{other_user.id}/follow", headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:created)
          expect(JSON.parse(response.body)['message']).to eq('Successfully followed user')
          expect(user.followed_users).to include(other_user)
        end
      end
    end

    context 'when trying to follow yourself' do
      it 'returns error' do
        post "/api/v1/users/#{user.id}/follow", headers: headers
        
        aggregate_failures do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['error']).to eq('Cannot follow yourself')
        end
      end
    end

    context 'when trying to follow a non-existent user' do
      it 'returns error' do
        post "/api/v1/users/99999/follow", headers: headers
        
        aggregate_failures do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['error']).to eq('User not found')
        end
      end
    end

    context 'when already following the user' do
      before do
        create(:follow, follower: user, followed: other_user)
      end

      it 'returns error' do
        post "/api/v1/users/#{other_user.id}/follow", headers: headers
        aggregate_failures do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['error']).to include('is already following this user')
        end
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        post "/api/v1/users/#{other_user.id}/follow"
        aggregate_failures do
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end

  describe 'DELETE /api/v1/users/:id/unfollow' do
    context 'when unfollowing a user you are following' do
      before do
        create(:follow, follower: user, followed: other_user)
      end

      it 'removes the follow relationship' do
        delete "/api/v1/users/#{other_user.id}/unfollow", headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(user.followed_users).not_to include(other_user)
        end
      end
    end

    context 'when trying to unfollow a user you are not following' do
      it 'returns error' do
        delete "/api/v1/users/#{other_user.id}/unfollow", headers: headers
        
        aggregate_failures do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['error']).to eq('Follow relationship not found')
        end
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        delete "/api/v1/users/#{other_user.id}/unfollow"
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/users/followers' do
    let!(:follower1) { create(:user) }
    let!(:follower2) { create(:user) }

    before do
      create(:follow, follower: follower1, followed: user)
      create(:follow, follower: follower2, followed: user)
    end

    it 'returns the user followers' do
      get '/api/v1/users/followers', headers: headers
      
      aggregate_failures do
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['followers'].length).to eq(2)
        expect(json_response['meta']['total_count']).to eq(2)
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        get '/api/v1/users/followers'
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/users/following' do
    let!(:followed1) { create(:user) }
    let!(:followed2) { create(:user) }

    before do
      create(:follow, follower: user, followed: followed1)
      create(:follow, follower: user, followed: followed2)
    end

    it 'returns the users being followed' do
      get '/api/v1/users/following', headers: headers
      
      aggregate_failures do
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['following'].length).to eq(2)
        expect(json_response['meta']['total_count']).to eq(2)
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        get '/api/v1/users/following'
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/users/:id/is_following' do
    context 'when following the user' do
      before do
        create(:follow, follower: user, followed: other_user)
      end

      it 'returns true' do
        get "/api/v1/users/#{other_user.id}/is_following", headers: headers
        
        aggregate_failures do
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response['is_following']).to be true
          expect(json_response['user_id']).to eq(other_user.id)
          expect(json_response['user_name']).to eq(other_user.name)
        end
      end
    end

    context 'when not following the user' do
      it 'returns false' do
        get "/api/v1/users/#{other_user.id}/is_following", headers: headers
        
        aggregate_failures do
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response['is_following']).to be false
        end
      end
    end

    context 'when user does not exist' do
      it 'returns not found' do
        get "/api/v1/users/99999/is_following", headers: headers
        
        aggregate_failures do
          expect(response).to have_http_status(:not_found)
          expect(JSON.parse(response.body)['error']).to eq('User not found')
        end
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        get "/api/v1/users/#{other_user.id}/is_following"
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end 