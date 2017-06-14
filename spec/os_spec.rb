require 'TerraformDevKit/os'

RSpec.describe TerraformDevKit::OS do
  describe '#join_env_path' do
    context 'OS is linux' do
      let(:path1) { 'pathA:pathB' }
      let(:path2) { 'pathC:pathD' }

      before(:example) do
        allow(TerraformDevKit::OS)
          .to receive(:host_os)
          .and_return('linux')
      end

      it 'joins environment path' do
        path = TerraformDevKit::OS.join_env_path(path1, path2)
        expect(path).to eq("#{path1}:#{path2}")
      end
    end

    context 'OS is MacOS' do
      let(:path1) { 'pathA:pathB' }
      let(:path2) { 'pathC:pathD' }

      before(:example) do
        allow(TerraformDevKit::OS)
          .to receive(:host_os)
          .and_return('darwin')
      end

      it 'joins environment path' do
        path = TerraformDevKit::OS.join_env_path(path1, path2)
        expect(path).to eq("#{path1}:#{path2}")
      end
    end

    context 'OS is windows' do
      let(:path1) { 'pathA;pathB' }
      let(:path2) { 'pathC;pathD' }

      before(:example) do
        allow(TerraformDevKit::OS)
          .to receive(:host_os)
          .and_return('windows')
      end

      it 'joins environment path' do
        path = TerraformDevKit::OS.join_env_path(path1, path2)
        expect(path).to eq("#{path1};#{path2}")
      end
    end
  end
end
