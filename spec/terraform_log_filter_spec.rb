require 'TerraformDevKit/terraform_log_filter'

RSpec.describe TerraformDevKit::TerraformLogFilter do
  it 'returns an empty list if input is empty' do
    output = TerraformDevKit::TerraformLogFilter.filter([])
    expect(output).to eq([])
  end

  it 'returns unmodified input if no log messages are present' do
    input = %w[line1 line2]
    output = TerraformDevKit::TerraformLogFilter.filter(input)
    expect(output).to eq(input)
  end

  it 'returns filtered input if log messages are present' do
    input = [
      'line1',
      '2017/01/01 10:00:00 [DEBUG] line2',
      'line3',
      '2017/01/01 10:00:01 [INFO] line4'
    ]
    output = TerraformDevKit::TerraformLogFilter.filter(input)
    expect(output).to eq(%w[line1 line3])
  end
end
