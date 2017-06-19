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

  describe '#convert_to_local_path' do
    let(:path) { 'a/b/c' }

    context 'OS is Unix-based' do
      before(:example) do
        stub_const('File::ALT_SEPARATOR', nil)
      end

      it 'leaves the path unchanged' do
        local_path = TerraformDevKit::OS.convert_to_local_path(path)
        expect(local_path).to eq(path)
      end
    end

    context 'OS is Windows' do
      before(:example) do
        stub_const('File::ALT_SEPARATOR', '\\')
      end

      it 'uses backslashes for the path' do
        local_path = TerraformDevKit::OS.convert_to_local_path(path)
        expect(local_path).to eq('a\b\c')
      end
    end

    it 'uses the OS-defined path separator' do
      local_path = TerraformDevKit::OS.convert_to_local_path(path)
      if TerraformDevKit::OS.host_os == 'windows'
        expect(local_path).to eq('a\b\c')
      else
        expect(local_path).to eq(path)
      end
    end
  end
end
