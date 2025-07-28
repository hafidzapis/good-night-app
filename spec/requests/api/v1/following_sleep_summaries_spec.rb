require 'rails_helper'

RSpec.describe 'Following Sleep Summaries API', type: :request do
  let(:user) { create(:user) }
  let(:followed_user1) { create(:user, name: 'Alice') }
  let(:followed_user2) { create(:user, name: 'Bob') }
  let(:non_followed_user) { create(:user, name: 'Charlie') }
  let(:headers) { { 'Authorization' => user.name } }

  before do
    create(:follow, follower: user, followed: followed_user1)
    create(:follow, follower: user, followed: followed_user2)
  end

  describe 'GET /api/v1/following_sleep_summaries' do
    context 'with sleep data from followed users' do
      let!(:summary1) { create(:daily_sleep_summary, user: followed_user1, date: 3.days.ago.to_date, total_sleep_duration_minutes: 480, number_of_sleep_sessions: 1) }
      let!(:summary2) { create(:daily_sleep_summary, user: followed_user1, date: 2.days.ago.to_date, total_sleep_duration_minutes: 420, number_of_sleep_sessions: 1) }
      let!(:summary3) { create(:daily_sleep_summary, user: followed_user2, date: 1.day.ago.to_date, total_sleep_duration_minutes: 360, number_of_sleep_sessions: 1) }
      let!(:summary4) { create(:daily_sleep_summary, user: non_followed_user, date: 2.days.ago.to_date, total_sleep_duration_minutes: 600, number_of_sleep_sessions: 1) }

      it 'returns friends summary for last week sorted by total sleep duration' do
        get '/api/v1/following_sleep_summaries', headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)

          expect(json_response['period']['start_date']).to eq(7.days.ago.to_date.to_s)
          expect(json_response['period']['end_date']).to eq(1.day.ago.to_date.to_s)

          friends_summary = json_response['friends_summary']
          expect(friends_summary.length).to eq(2)

          alice_summary = friends_summary.find { |f| f['user_name'] == 'Alice' }
          expect(alice_summary['user_id']).to eq(followed_user1.id)
          expect(alice_summary['total_sleep_duration_minutes']).to eq(900)
          expect(alice_summary['total_sleep_duration_hours']).to eq(15.0)
          expect(alice_summary['average_sleep_per_day_minutes']).to eq(450.0)
          expect(alice_summary['average_sleep_per_day_hours']).to eq(7.5)
          expect(alice_summary['total_number_of_sleep_sessions']).to eq(2)
          expect(alice_summary['average_sleep_sessions_per_day']).to eq(1.0)
          expect(alice_summary['days_with_sleep']).to eq(2)
          expect(alice_summary['total_days']).to eq(2)
          expect(alice_summary['sleep_efficiency_percentage']).to eq(100.0)

          bob_summary = friends_summary.find { |f| f['user_name'] == 'Bob' }
          expect(bob_summary['user_id']).to eq(followed_user2.id)
          expect(bob_summary['total_sleep_duration_minutes']).to eq(360)
          expect(bob_summary['total_sleep_duration_hours']).to eq(6.0)
          expect(bob_summary['average_sleep_per_day_minutes']).to eq(360.0)
          expect(bob_summary['average_sleep_per_day_hours']).to eq(6.0)
          expect(bob_summary['total_number_of_sleep_sessions']).to eq(1)
          expect(bob_summary['average_sleep_sessions_per_day']).to eq(1.0)
          expect(bob_summary['days_with_sleep']).to eq(1)
          expect(bob_summary['total_days']).to eq(1)
          expect(bob_summary['sleep_efficiency_percentage']).to eq(100.0)

          pagination = json_response['pagination']
          expect(pagination['current_page']).to eq(1)
          expect(pagination['per_page']).to eq(25)
          expect(pagination['total_count']).to eq(2)
          expect(pagination['total_pages']).to eq(1)
          expect(pagination['has_next_page']).to be false
          expect(pagination['has_prev_page']).to be false
        end
      end
    end

    context 'with custom date range' do
      let!(:summary1) { create(:daily_sleep_summary, user: followed_user1, date: Date.parse('2024-01-01'), total_sleep_duration_minutes: 480, number_of_sleep_sessions: 1) }
      let!(:summary2) { create(:daily_sleep_summary, user: followed_user1, date: Date.parse('2024-01-02'), total_sleep_duration_minutes: 420, number_of_sleep_sessions: 2) }
      let!(:summary3) { create(:daily_sleep_summary, user: followed_user2, date: Date.parse('2024-01-01'), total_sleep_duration_minutes: 360, number_of_sleep_sessions: 1) }

      it 'returns friends summary for specified date range' do
        get '/api/v1/following_sleep_summaries', params: { start_date: '2024-01-01', end_date: '2024-01-02' }, headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)

          expect(json_response['period']['start_date']).to eq('2024-01-01')
          expect(json_response['period']['end_date']).to eq('2024-01-02')

          friends_summary = json_response['friends_summary']
          expect(friends_summary.length).to eq(2)

          alice_summary = friends_summary.find { |f| f['user_name'] == 'Alice' }
          expect(alice_summary['total_sleep_duration_minutes']).to eq(900)
          expect(alice_summary['total_days']).to eq(2)

          bob_summary = friends_summary.find { |f| f['user_name'] == 'Bob' }
          expect(bob_summary['total_sleep_duration_minutes']).to eq(360)
          expect(bob_summary['total_days']).to eq(1)
        end
      end
    end

    context 'with pagination' do
      let!(:followed_users) do
        (1..28).map { |i| create(:user, name: "User#{i}") }
      end

      before do
        followed_users.each { |u| create(:follow, follower: user, followed: u) }
      end

      it 'returns paginated results' do
        get '/api/v1/following_sleep_summaries', params: { page: 2, per: 10 }, headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)

          expect(json_response['friends_summary'].length).to eq(10)
          
          pagination = json_response['pagination']
          expect(pagination['current_page']).to eq(2)
          expect(pagination['per_page']).to eq(10)
          expect(pagination['total_count']).to eq(30)
          expect(pagination['total_pages']).to eq(3)
          expect(pagination['has_next_page']).to be true
          expect(pagination['has_prev_page']).to be true
        end
      end
    end

    context 'with invalid date parameters' do
      it 'falls back to default date range' do
        get '/api/v1/following_sleep_summaries', params: { start_date: 'invalid-date', end_date: 'also-invalid' }, headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)

          expect(json_response['period']['start_date']).to eq(7.days.ago.to_date.to_s)
          expect(json_response['period']['end_date']).to eq(1.day.ago.to_date.to_s)
        end
      end
    end

    context 'with date range too large' do
      it 'returns error for date range exceeding limit' do
        get '/api/v1/following_sleep_summaries', params: { start_date: '2024-01-01', end_date: '2024-06-01' }, headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:bad_request)
          json_response = JSON.parse(response.body)
          expect(json_response['error']['error']).to eq('Date range is too long')
        end
      end
    end

    context 'with no followed users' do
      let(:user_without_following) { create(:user, name: 'Lonely') }
      let(:lonely_headers) { { 'Authorization' => user_without_following.name } }

      it 'returns empty friends summary' do
        get '/api/v1/following_sleep_summaries', headers: lonely_headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)

          expect(json_response['friends_summary']).to be_empty
          expect(json_response['pagination']['total_count']).to eq(0)
        end
      end
    end

    context 'with no sleep data from followed users' do
      it 'returns friends with zero sleep data' do
        get '/api/v1/following_sleep_summaries', headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)

          friends_summary = json_response['friends_summary']
          expect(friends_summary.length).to eq(2)

          friends_summary.each do |friend|
            expect(friend['total_sleep_duration_minutes']).to eq(0)
            expect(friend['total_sleep_duration_hours']).to eq(0)
            expect(friend['average_sleep_per_day_minutes']).to eq(0)
            expect(friend['average_sleep_per_day_hours']).to eq(0)
            expect(friend['total_number_of_sleep_sessions']).to eq(0)
            expect(friend['average_sleep_sessions_per_day']).to eq(0)
            expect(friend['days_with_sleep']).to eq(0)
            expect(friend['total_days']).to eq(0)
            expect(friend['sleep_efficiency_percentage']).to eq(0)
          end
        end
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        get '/api/v1/following_sleep_summaries'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with same total sleep duration from different users' do
      let!(:summary1) { create(:daily_sleep_summary, user: followed_user1, date: 1.day.ago.to_date, total_sleep_duration_minutes: 480, number_of_sleep_sessions: 1) }
      let!(:summary2) { create(:daily_sleep_summary, user: followed_user2, date: 1.day.ago.to_date, total_sleep_duration_minutes: 480, number_of_sleep_sessions: 1) }

      it 'sorts by name when sleep duration is equal' do
        get '/api/v1/following_sleep_summaries', headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)

          friends_summary = json_response['friends_summary']
          expect(friends_summary.length).to eq(2)
          expect(friends_summary[0]['user_name']).to eq('Alice')
          expect(friends_summary[1]['user_name']).to eq('Bob')
          expect(friends_summary[0]['total_sleep_duration_minutes']).to eq(480)
          expect(friends_summary[1]['total_sleep_duration_minutes']).to eq(480)
        end
      end
    end

    context 'with partial sleep data (some days with no sleep)' do
      let!(:summary1) { create(:daily_sleep_summary, user: followed_user1, date: 3.days.ago.to_date, total_sleep_duration_minutes: 480, number_of_sleep_sessions: 1) }
      let!(:summary2) { create(:daily_sleep_summary, user: followed_user1, date: 2.days.ago.to_date, total_sleep_duration_minutes: 0, number_of_sleep_sessions: 0) }
      let!(:summary3) { create(:daily_sleep_summary, user: followed_user1, date: 1.day.ago.to_date, total_sleep_duration_minutes: 360, number_of_sleep_sessions: 1) }

      it 'calculates sleep efficiency correctly per friend' do
        get '/api/v1/following_sleep_summaries', headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)

          alice_summary = json_response['friends_summary'].find { |f| f['user_name'] == 'Alice' }
          expect(alice_summary['total_sleep_duration_minutes']).to eq(840)
          expect(alice_summary['total_number_of_sleep_sessions']).to eq(2)
          expect(alice_summary['days_with_sleep']).to eq(2)
          expect(alice_summary['total_days']).to eq(3)
          expect(alice_summary['sleep_efficiency_percentage']).to eq(66.67)
        end
      end
    end

    context 'with sleep data outside last week' do
      let!(:old_summary) { create(:daily_sleep_summary, user: followed_user1, date: 10.days.ago.to_date, total_sleep_duration_minutes: 600, number_of_sleep_sessions: 1) }
      let!(:recent_summary) { create(:daily_sleep_summary, user: followed_user1, date: 2.days.ago.to_date, total_sleep_duration_minutes: 480, number_of_sleep_sessions: 1) }

      it 'only includes data from last week' do
        get '/api/v1/following_sleep_summaries', headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)

          alice_summary = json_response['friends_summary'].find { |f| f['user_name'] == 'Alice' }
          expect(alice_summary['total_sleep_duration_minutes']).to eq(480)
          expect(alice_summary['total_days']).to eq(1)
        end
      end
    end
  end
end 