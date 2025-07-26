require 'rails_helper'

RSpec.describe 'Api::V1::Users', type: :request do
  describe 'GET /api/v1/users' do
    let!(:users) { create_list(:user, 30) }

    it 'returns paginated users' do
      get '/api/v1/users'
      
      aggregate_failures do
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['users'].length).to eq(25) # default per_page
        expect(json_response['meta']['current_page']).to eq(1)
        expect(json_response['meta']['total_count']).to eq(30)
        expect(json_response['meta']['total_pages']).to eq(2)
      end
    end

    it 'accepts pagination parameters' do
      get '/api/v1/users', params: { page: 2, per_page: 10 }
      
      aggregate_failures do
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['users'].length).to eq(10)
        expect(json_response['meta']['current_page']).to eq(2)
      end
    end
  end

  describe 'GET /api/v1/users/:id' do
    let(:user) { create(:user) }

    it 'returns the user' do
      get "/api/v1/users/#{user.id}"
      
      aggregate_failures do
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(user.id)
        expect(json_response['name']).to eq(user.name)
      end
    end

    it 'returns 404 for non-existent user' do
      get '/api/v1/users/999'
      
      aggregate_failures do
        expect(response).to have_http_status(:not_found)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('User not found')
      end
    end
  end

  describe 'POST /api/v1/users' do
    let(:valid_params) { { user: { name: 'John Doe' } } }
    let(:invalid_params) { { user: { name: '' } } }

    it 'creates a new user with valid params' do
      expect {
        post '/api/v1/users', params: valid_params
      }.to change(User, :count).by(1)
      
      aggregate_failures do
        expect(response).to have_http_status(:created)
        
        json_response = JSON.parse(response.body)
        expect(json_response['name']).to eq('John Doe')
      end
    end

    it 'returns errors with invalid params' do
      post '/api/v1/users', params: invalid_params
      
      aggregate_failures do
        expect(response).to have_http_status(:unprocessable_entity)
        
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("Name can't be blank")
      end
    end
  end
end 