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

  describe '#render_paginated_collection' do
    let(:collection) { double('collection') }

    before do
      allow(helper).to receive(:pagination_meta).and_return({ current_page: 1 })
    end

    it 'returns the correct hash structure' do
      result = helper.render_paginated_collection(collection, :users)
      
      expect(result).to eq({
        json: {
          users: collection,
          meta: { current_page: 1 }
        }
      })
    end
  end

  describe '#render_success' do
    it 'returns success message with default status' do
      result = helper.render_success('Success!')
      
      expect(result).to eq({
        json: { message: 'Success!' },
        status: :ok
      })
    end

    it 'returns success message with custom status' do
      result = helper.render_success('Created!', :created)
      
      expect(result).to eq({
        json: { message: 'Created!' },
        status: :created
      })
    end
  end

  describe '#render_error' do
    it 'returns error with default status' do
      result = helper.render_error('Something went wrong')
      
      expect(result).to eq({
        json: { error: 'Something went wrong' },
        status: :unprocessable_entity
      })
    end

    it 'returns error with custom status' do
      result = helper.render_error('Not found', :not_found)
      
      expect(result).to eq({
        json: { error: 'Not found' },
        status: :not_found
      })
    end
  end
end 