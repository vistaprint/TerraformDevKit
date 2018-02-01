require 'TerraformDevKit/config'
require 'TerraformDevKit/environment'
require 'TerraformDevKit/terraform_config_manager'

require 'fileutils'
require 'tmpdir'

TDK = TerraformDevKit

RSpec.describe TDK::TerraformConfigManager do
  describe '#update_modules?' do
    before(:example) do
      @saved_env_var = ENV['TF_DEVKIT_UPDATE_MODULES']
    end

    after(:example) do
      if @saved_env_var.nil?
        ENV.delete('TF_DEVKIT_UPDATE_MODULES')
      else
        ENV['TF_DEVKIT_UPDATE_MODULES'] = @saved_env_var
      end
    end

    context 'env var is not set' do
      it 'returns false' do
        expect(TDK::TerraformConfigManager.update_modules?).to be false
      end
    end

    context 'env var is set' do
      [
        { value: 'true',  expected: true },
        { value: 'false', expected: false },
        { value: 'foo',   expected: false }
      ].each do |example|
        it 'updates modules only if env var is true' do
          ENV['TF_DEVKIT_UPDATE_MODULES'] = example[:value]
          expect(TDK::TerraformConfigManager.update_modules?)
            .to eq(example[:expected])
        end
      end
    end
  end
end
