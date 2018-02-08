require 'TerraformDevKit/project_config'

TDK = TerraformDevKit

RSpec.describe TerraformDevKit::ProjectConfig do
  it 'should sanitise project name' do
    project_config = TDK::ProjectConfig.new('Some project Name')

    expect(project_config.name).to eq('some-project-name')
  end

  it 'should generate project acronym from project name' do
    project_config = TDK::ProjectConfig.new('Some project Name')

    expect(project_config.acronym).to eq('SPN')
  end

  it 'should use project acronym if given' do
    project_config = TDK::ProjectConfig.new('Some project Name', 'FOO')

    expect(project_config.acronym).to eq('FOO')
  end
end
