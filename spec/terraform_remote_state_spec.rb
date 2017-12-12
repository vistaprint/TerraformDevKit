require 'TerraformDevKit/terraform_remote_state'

RSpec.describe TerraformDevKit::TerraformRemoteState do
  let!(:dynamodb_double) { double() }
  let!(:s3_double) { double() }

  let(:project_name) { 'dummy-project' }
  let(:project_double) { double(name: project_name, acronym: 'DP') }
  let(:environment_double) { double(name: 'dev') }

  let(:terraform_remote_state) { 
    TerraformDevKit::TerraformRemoteState.new(dynamodb_double, s3_double) 
  }

  let(:attributes) {
    [{
      attribute_name: 'LockID',
      attribute_type: 'S'
    }]
  }

  let(:keys) {
    [{
      attribute_name: 'LockID',
      key_type: 'HASH'
    }]
  }

  let(:table_name) { 'DP-dev-lock-table' }
  let(:bucket_name) { 'dummy-project-dev-state' }

  describe '#init' do
    context 'when lock table does not exist' do
      it 'creates the lock table and waits for it to become active' do
        allow(dynamodb_double)
          .to receive(:get_table_status)
          .with(table_name)
          .and_return('INACTIVE', 'INACTIVE', 'ACTIVE')

        allow(dynamodb_double)
          .to receive(:create_table)
          .with(table_name, attributes, keys, 1, 1)

        allow(s3_double)
          .to receive(:create_bucket)
          .with(project_name)

        expect(dynamodb_double)
          .to receive(:create_table)
          .with(table_name, attributes, keys, 1, 1)
          .once

        expect(s3_double)
          .to receive(:create_bucket)
          .with(bucket_name)

        expect(dynamodb_double)
          .to receive(:get_table_status)
          .exactly(3)
          .times

        terraform_remote_state
          .init(environment_double, project_double)
      end
    end

    context 'when lock table exists and is active' do
      it 'should do nothing' do
        expect(dynamodb_double)
          .to receive(:get_table_status)
          .and_return('ACTIVE')
          .once

        expect(s3_double)
          .to receive(:create_bucket)
          .never

        expect(dynamodb_double)
          .to receive(:create_table)
          .never

        terraform_remote_state
          .init(environment_double, project_double)
      end
    end
  end

  describe '#destroy' do
    context 'when lock table exists and is active' do
      it 'should delete the table and s3 bucket' do
        expect(dynamodb_double)
          .to receive(:delete_table)
          .with(table_name)
          .once

        expect(s3_double)
          .to receive(:delete_bucket)
          .with(bucket_name)
          .once

        terraform_remote_state.destroy(environment_double, project_double)
      end
    end
  end
end
