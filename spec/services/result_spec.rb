require 'rails_helper'

RSpec.describe Result do
  describe '.success' do
    it 'creates a successful result with data' do
      data = { key: 'value' }
      result = described_class.success(data)

      expect(result.success?).to be true
      expect(result.failure?).to be false
      expect(result.data).to eq(data)
      expect(result.error).to be_nil
    end

    it 'creates a successful result without data' do
      result = described_class.success

      expect(result.success?).to be true
      expect(result.failure?).to be false
      expect(result.data).to be_nil
      expect(result.error).to be_nil
    end
  end

  describe '.failure' do
    it 'creates a failed result with error' do
      error = 'Something went wrong'
      result = described_class.failure(error)

      expect(result.success?).to be false
      expect(result.failure?).to be true
      expect(result.data).to be_nil
      expect(result.error).to eq(error)
    end
  end

  describe 'instance methods' do
    let(:success_result) { described_class.new(success: true, data: 'success data') }
    let(:failure_result) { described_class.new(success: false, error: 'error message') }

    describe '#success?' do
      it 'returns true for successful result' do
        expect(success_result.success?).to be true
      end

      it 'returns false for failed result' do
        expect(failure_result.success?).to be false
      end
    end

    describe '#failure?' do
      it 'returns false for successful result' do
        expect(success_result.failure?).to be false
      end

      it 'returns true for failed result' do
        expect(failure_result.failure?).to be true
      end
    end
  end
end 