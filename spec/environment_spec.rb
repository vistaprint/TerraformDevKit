require 'fileutils'
require 'TerraformDevKit/environment'

TDK = TerraformDevKit

ROOT_PATH = 'C:/some/root/path'

RSpec.describe TerraformDevKit::Environment do
  describe '#initialize' do
    [nil, '', 'foo#bar', 'foo-bar', 'foo_bar', 'foo+bar', '#'].each do |name|
      it 'raises an error when name is not alphanumeric' do
        expect { TDK::Environment.new(name) }
          .to raise_error("Invalid environment name: #{name}")
      end
    end

    it 'does not raise an error if name is alphanumeric' do
      TDK::Environment.new('foobar123')
    end
  end

  describe '#config' do
    it 'detects prod and test environments' do
      expect(TDK::Environment.new('prod').config).to eq('prod')
      expect(TDK::Environment.new('test').config).to eq('test')
    end

    it 'defaults to dev otherwise' do
      expect(TDK::Environment.new('foobar').config).to eq('dev')
    end
  end

  describe '#local_backend?' do
    it 'uses remote backend for prod and test' do
      expect(TDK::Environment.new('prod').local_backend?).to be false
      expect(TDK::Environment.new('test').local_backend?).to be false
    end

    it 'uses a local backend otherwise' do
      expect(TDK::Environment.new('foobar').local_backend?).to be true
    end
  end

  describe '#working_dir' do
    it 'prefixes environment name correctly' do
      dir = TDK::Environment.new('foobar').working_dir
      expect(dir).to eq(File.join(ROOT_PATH,'envs', 'foobar'))
    end
  end

  describe '#temp_name' do
    it 'constructs a temporal name with the hostname and date' do
      time = Time.new(2017, 1, 2, 15, 30)
      allow(Time).to receive(:now).and_return(time)
      allow(Socket).to receive(:gethostname).and_return('foobar')
      name = TDK::Environment.temp_name
      expect(name).to eq('foobar1701021530')
    end

    it 'removes invalid characters' do
      time = Time.new(2017, 1, 2, 15, 30)
      allow(Time).to receive(:now).and_return(time)
      allow(Socket).to receive(:gethostname).and_return('#foo-bar@')
      name = TDK::Environment.temp_name
      expect(name).to eq('foobar1701021530')
    end
  end

  describe '#running_on_jenkins?' do
    context 'env vars not defined' do
      before(:example) do
        @env = ENV.to_h
        ENV.delete('JENKINS_URL')
        ENV.delete('BUILD_ID')
      end

      after(:example) do
        ENV.replace(@env)
      end

      it 'does not detect jenkins' do
        expect(TDK::Environment.running_on_jenkins?).to be false
      end
    end

    context 'env vars defined' do
      before(:example) do
        @env = ENV.to_h
        ENV['JENKINS_URL'] = 'some_url'
        ENV['BUILD_ID'] = 'some_build_id'
      end

      after(:example) do
        ENV.replace(@env)
      end

      it 'does detect jenkins' do
        expect(TDK::Environment.running_on_jenkins?).to be true
      end
    end
  end
end
