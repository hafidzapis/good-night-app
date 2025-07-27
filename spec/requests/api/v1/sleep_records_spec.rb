require 'rails_helper'

RSpec.describe 'Api::V1::SleepRecords', type: :request do
  let(:user) { create(:user, name: 'William') }
  let(:headers) { { 'Authorization' => user.name } }

  describe 'POST /api/v1/sleep_records/clock_in' do
    context 'with valid authentication' do
      context 'when user has no active sleep record' do
        it 'creates a new sleep record' do
          expect {
            post '/api/v1/sleep_records/clock_in', headers: headers
          }.to change(Sleep, :count).by(1)

          expect(response).to have_http_status(:created)
          
          json_response = JSON.parse(response.body)
          expect(json_response['sleep_record']).to be_present
          expect(json_response['sleep_record']['clock_in_time']).to be_present
          expect(json_response['sleep_record']['clock_out_time']).to be_nil
        end

        it 'sets the clock_in_time to current time' do
          Timecop.freeze do
            post '/api/v1/sleep_records/clock_in', headers: headers
            
            json_response = JSON.parse(response.body)
            clock_in_time = Time.zone.parse(json_response['sleep_record']['clock_in_time'])
            expect(clock_in_time).to be_within(1.second).of(Time.zone.now)
          end
        end
      end

      context 'when user already has an active sleep record' do
        before do
          create(:sleep, :active, user: user)
        end

        it 'returns an error' do
          post '/api/v1/sleep_records/clock_in', headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('User already has an active sleep record')
        end

        it 'does not create a new sleep record' do
          expect {
            post '/api/v1/sleep_records/clock_in', headers: headers
          }.not_to change(Sleep, :count)
        end
      end
    end

    context 'with invalid authentication' do
      it 'returns unauthorized when no authorization header' do
        post '/api/v1/sleep_records/clock_in'

        expect(response).to have_http_status(:unauthorized)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unauthorized')
      end

      it 'returns unauthorized when user does not exist' do
        post '/api/v1/sleep_records/clock_in', headers: { 'Authorization' => 'NonExistentUser' }

        expect(response).to have_http_status(:unauthorized)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unauthorized')
      end
    end
  end

  describe 'PATCH /api/v1/sleep_records/:id/clock_out' do
    let(:sleep_record) { create(:sleep, :active, user: user, clock_in_time: 1.hour.ago) }

    context 'with valid authentication' do
      context 'when sleep record exists and is active' do
        it 'updates the sleep record with clock out time' do
          Timecop.freeze do
            patch "/api/v1/sleep_records/#{sleep_record.id}/clock_out", headers: headers

            expect(response).to have_http_status(:ok)
            
            json_response = JSON.parse(response.body)
            expect(json_response['clock_out_time']).to be_present
            expect(json_response['duration_minutes']).to be_present
            expect(json_response['duration_minutes']).to be > 0
          end
        end

        it 'calculates duration correctly' do
          clock_in_time = 2.hours.ago
          sleep_record.update!(clock_in_time: clock_in_time)
          
          Timecop.freeze do
            patch "/api/v1/sleep_records/#{sleep_record.id}/clock_out", headers: headers
            
            json_response = JSON.parse(response.body)
            expected_duration = ((Time.zone.now - clock_in_time) / 60).to_i
            expect(json_response['duration_minutes']).to eq(expected_duration)
          end
        end
      end

      context 'when sleep record is already clocked out' do
        before do
          sleep_record.update!(clock_out_time: 30.minutes.ago)
        end

        it 'returns an error' do
          patch "/api/v1/sleep_records/#{sleep_record.id}/clock_out", headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('Sleep record has already been clocked out')
        end
      end

      context 'when sleep record does not exist' do
        it 'returns an error' do
          patch '/api/v1/sleep_records/999/clock_out', headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('Sleep record not found')
        end
      end

      context 'when sleep record belongs to different user' do
        let(:other_user) { create(:user, name: 'Jane Doe') }
        let(:other_sleep_record) { create(:sleep, :active, user: other_user) }

        it 'returns an error' do
          patch "/api/v1/sleep_records/#{other_sleep_record.id}/clock_out", headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('Sleep record not found')
        end
      end
    end

    context 'with invalid authentication' do
      it 'returns unauthorized when no authorization header' do
        patch "/api/v1/sleep_records/#{sleep_record.id}/clock_out"

        expect(response).to have_http_status(:unauthorized)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unauthorized')
      end

      it 'returns unauthorized when user does not exist' do
        patch "/api/v1/sleep_records/#{sleep_record.id}/clock_out", 
              headers: { 'Authorization' => 'NonExistentUser' }

        expect(response).to have_http_status(:unauthorized)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unauthorized')
      end
    end
  end
end 