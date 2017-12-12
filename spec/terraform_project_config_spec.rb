require 'TerraformDevKit/terraform_project_config'

RSpec.describe TerraformDevKit::TerraformProjectConfig do
  it 'should sanitise project name' do
    terraform_project_config = TerraformDevKit::TerraformProjectConfig.new('Some project Name')

    expect(terraform_project_config.name).to eq('some-project-name')
  end

  it 'should generate project acronym from project name' do
    terraform_project_config = TerraformDevKit::TerraformProjectConfig.new('Some project Name')

    expect(terraform_project_config.acronym).to eq('SPN')
  end
end
