require 'TerraformDevKit/retry'

TDK = TerraformDevKit

RSpec.describe 'TerraformDevKit.with_retry' do
  context 'no need to retry' do
    it 'does not retry' do
      count = 0
      TDK.with_retry(5) do
        count += 1
      end

      expect(count).to eq(1)
    end
  end

  context 'retry is needed' do
    it 'retries until success' do
      count = 0
      TDK.with_retry(10, sleep_time: 0) do
        count += 1
        raise 'failure' if count < 5
      end

      expect(count).to eq(5)
    end

    it 'does not exceed the retry count' do
      count = 0
      expect {
        TDK.with_retry(5, sleep_time: 0) do
          count += 1
          raise 'failure' if count < 10
        end
      }.to raise_error('failure')

      expect(count).to eq(5)
    end
  end
end
