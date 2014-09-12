$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)
require 'rspec'
require 'image_optim/config'

describe ImageOptim::Config do
  Config = ImageOptim::Config

  describe 'assert_no_unused_options!' do
    before do
      allow(Config).to receive(:read_options).and_return({})
    end

    it 'should not raise when no unused options' do
      config = Config.new({})
      config.assert_no_unused_options!
    end

    it 'should raise when there are unused options' do
      config = Config.new(:unused => true)
      expect do
        config.assert_no_unused_options!
      end.to raise_error(ImageOptim::ConfigurationError)
    end
  end

  describe 'nice' do
    before do
      allow(Config).to receive(:read_options).and_return({})
    end

    it 'should be 10 by default' do
      config = Config.new({})
      expect(config.nice).to eq(10)
    end

    it 'should be 0 if disabled' do
      config = Config.new(:nice => false)
      expect(config.nice).to eq(0)
    end

    it 'should convert value to number' do
      config = Config.new(:nice => '13')
      expect(config.nice).to eq(13)
    end
  end

  describe 'threads' do
    before do
      allow(Config).to receive(:read_options).and_return({})
    end

    it 'should be processor_count by default' do
      config = Config.new({})
      allow(config).to receive(:processor_count).and_return(13)
      expect(config.threads).to eq(13)
    end

    it 'should be 1 if disabled' do
      config = Config.new(:threads => false)
      expect(config.threads).to eq(1)
    end

    it 'should convert value to number' do
      config = Config.new(:threads => '616')
      expect(config.threads).to eq(616)
    end
  end

  describe 'for_worker' do
    before do
      allow(Config).to receive(:read_options).and_return({})
    end

    Abc = Class.new do
      def self.bin_sym
        :abc
      end

      def image_formats
        []
      end
    end

    it 'should return empty hash by default' do
      config = Config.new({})
      expect(config.for_worker(Abc)).to eq({})
    end

    it 'should return passed hash' do
      config = Config.new(:abc => {:option => true})
      expect(config.for_worker(Abc)).to eq(:option => true)
    end

    it 'should return passed false' do
      config = Config.new(:abc => false)
      expect(config.for_worker(Abc)).to eq(false)
    end

    it 'should raise on unknown option' do
      config = Config.new(:abc => 13)
      expect do
        config.for_worker(Abc)
      end.to raise_error(ImageOptim::ConfigurationError)
    end
  end

  describe 'config' do
    it 'should read options from default locations' do
      expect(Config).to receive(:read_options).
        with(Config::GLOBAL_PATH).and_return(:a => 1, :b => 2, :c => 3)
      expect(Config).to receive(:read_options).
        with(Config::LOCAL_PATH).and_return(:a => 10, :b => 20)

      config = Config.new(:a => 100)
      expect(config.get!(:a)).to eq(100)
      expect(config.get!(:b)).to eq(20)
      expect(config.get!(:c)).to eq(3)
      config.assert_no_unused_options!
    end

    it 'should not read options with empty config_paths' do
      expect(Config).not_to receive(:read_options)

      config = Config.new(:config_paths => [])
      config.assert_no_unused_options!
    end

    it 'should read options from specified paths' do
      expect(Config).to receive(:read_options).
        with('/etc/image_optim.yml').and_return(:a => 1, :b => 2, :c => 3)
      expect(Config).to receive(:read_options).
        with('config/image_optim.yml').and_return(:a => 10, :b => 20)

      config = Config.new(:a => 100, :config_paths => %w[
        /etc/image_optim.yml
        config/image_optim.yml
      ])
      expect(config.get!(:a)).to eq(100)
      expect(config.get!(:b)).to eq(20)
      expect(config.get!(:c)).to eq(3)
      config.assert_no_unused_options!
    end

    it 'should convert config_paths to array' do
      expect(Config).to receive(:read_options).
        with('config/image_optim.yml').and_return({})

      config = Config.new(:config_paths => 'config/image_optim.yml')
      config.assert_no_unused_options!
    end
  end

  describe 'class methods' do
    describe 'read_options' do
      let(:path){ double(:path) }
      let(:full_path){ double(:full_path) }

      it 'should warn if expand path fails' do
        expect(Config).to receive(:warn)
        expect(File).to receive(:expand_path).
          with(path).and_raise(ArgumentError)
        expect(File).not_to receive(:file?)

        expect(Config.read_options(path)).to eq({})
      end

      it 'should return empty hash if path is not a file' do
        expect(Config).not_to receive(:warn)
        expect(File).to receive(:expand_path).
          with(path).and_return(full_path)
        expect(File).to receive(:file?).
          with(full_path).and_return(false)

        expect(Config.read_options(path)).to eq({})
      end

      it 'should return hash with deep symbolised keys from reader' do
        stringified = {'config' => {'this' => true}}
        symbolized = {:config => {:this => true}}

        expect(Config).not_to receive(:warn)
        expect(File).to receive(:expand_path).
          with(path).and_return(full_path)
        expect(File).to receive(:file?).
          with(full_path).and_return(true)
        expect(YAML).to receive(:load_file).
          with(full_path).and_return(stringified)

        expect(Config.read_options(path)).to eq(symbolized)
      end

      it 'should warn and return an empty hash if reader returns non hash' do
        expect(Config).to receive(:warn)
        expect(File).to receive(:expand_path).
          with(path).and_return(full_path)
        expect(File).to receive(:file?).
          with(full_path).and_return(true)
        expect(YAML).to receive(:load_file).
          with(full_path).and_return([:config])

        expect(Config.read_options(path)).to eq({})
      end

      it 'should warn and return an empty hash if reader raises exception' do
        expect(Config).to receive(:warn)
        expect(File).to receive(:expand_path).
          with(path).and_return(full_path)
        expect(File).to receive(:file?).
          with(full_path).and_return(true)
        expect(YAML).to receive(:load_file).
          with(full_path).and_raise

        expect(Config.read_options(path)).to eq({})
      end
    end
  end
end
