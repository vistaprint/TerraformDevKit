require 'spec_helper'

RSpec.describe TerraformDevKit do
  it 'has a version number' do
    expect(TerraformDevKit::VERSION).not_to be nil
  end
end
