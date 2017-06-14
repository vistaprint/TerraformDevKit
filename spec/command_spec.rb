require 'TerraformDevKit/command'

RSpec.describe TerraformDevKit::Command do
  it 'returns command output' do
    result = TerraformDevKit::Command.run('sh -c "echo Test Output"')
    expect(result).to eq("Test Output\n")
  end

  it 'throws an exception if command fails' do
    expect { TerraformDevKit::Command.run('sh -c "exit 1"') }
      .to raise_error('Error running command sh -c "exit 1"')
  end
end
