require 'TerraformDevKit/project_config'

RSpec.describe TerraformDevKit::ProjectConfig do
  it 'should sanitise project name' do
    terraform_project_config = TerraformDevKit::ProjectConfig.new('Some project Name')

    expect(terraform_project_config.name).to eq('some-project-name')
  end

  it 'should generate project acronym from project name' do
    terraform_project_config = TerraformDevKit::ProjectConfig.new('Some project Name')

    expect(terraform_project_config.acronym).to eq('SPN')
  end

  it 'should use project acronym if given' do
    terraform_project_config = TerraformDevKit::ProjectConfig.new('Some project Name', 'FOO')

    expect(terraform_project_config.acronym).to eq('FOO')
  end
end
