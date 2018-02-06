require 'TerraformDevKit/command'
require 'TerraformDevKit/os'

TDK = TerraformDevKit

RSpec.describe TDK::Command do
  it 'returns command output' do
    result = TDK::Command.run('printf "Line1\nLine2"', print_output: false)
    expect(result).to eq(%w[Line1 Line2])
  end

  it 'throws an exception if command fails' do
    if TDK::OS.host_os == 'windows'
      expect { TDK::Command.run('cmd /c exit 1') }
        .to raise_error(TDK::CommandError) do |error|
          expect(error.cmd).to eq('cmd /c exit 1')
        end
    else
      expect { TDK::Command.run('sh -c "exit 1"') }
        .to raise_error(TDK::CommandError) do |error|
          expect(error.cmd).to eq('sh -c "exit 1"')
        end
    end
  end
end
