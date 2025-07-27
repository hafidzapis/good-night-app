require 'rails_helper'

RSpec.describe Api::V1::ApiHelper do
  let(:dummy_class) { Class.new { include Api::V1::ApiHelper } }
  let(:helper) { dummy_class.new }

  describe '#pagination_meta' do
    let(:collection) { double('collection') }

    before do
      allow(collection).to receive(:current_page).and_return(2)
      allow(collection).to receive(:next_page).and_return(3)
      allow(collection).to receive(:prev_page).and_return(1)
      allow(collection).to receive(:total_pages).and_return(5)
      allow(collection).to receive(:total_count).and_return(100)
    end

    it 'returns pagination meta hash' do
      result = helper.pagination_meta(collection)
      
      expect(result).to eq({
        current_page: 2,
        next_page: 3,
        prev_page: 1,
        total_pages: 5,
        total_count: 100
      })
    end
  end
end 