# encoding: utf-8

require File.expand_path('../../spec_helper.rb', __FILE__)

module Backup
describe Storage::Qiniu do
  let(:model) { Model.new(:test_trigger, 'test label') }
  let(:required_config) {
    Proc.new do |qiniu|
      qiniu.access_key_id      = 'my_access_key_id'
      qiniu.secret_access_key  = 'my_secret_access_key'
      qiniu.bucket             = 'my_bucket'
    end
  }
  let(:storage) { Storage::Qiniu.new(model, &required_config) }

  it_behaves_like 'a subclass of Storage::Base'

  describe '#initialize' do
    it 'provides required values' do
      expect( storage.access_key_id     ).to eq 'my_access_key_id'
      expect( storage.secret_access_key ).to eq 'my_secret_access_key'
      expect( storage.bucket            ).to eq 'my_bucket'
    end

    it 'strips leading path separator' do
      pre_config = required_config
      storage = Storage::Qiniu.new(model) do |qiniu|
        pre_config.call(qiniu)
        qiniu.path = '/this/path'
      end
      expect( storage.path ).to eq 'this/path'
    end

    it 'requires access_key_id' do
      pre_config = required_config
      expect do
        Storage::Qiniu.new(model) do |qiniu|
          pre_config.call(qiniu)
          qiniu.access_key_id = nil
        end
      end.to raise_error {|err|
        expect( err.message ).to match(/are all required/)
      }
    end

    it 'requires secret_access_key' do
      pre_config = required_config
      expect do
        Storage::Qiniu.new(model) do |qiniu|
          pre_config.call(qiniu)
          qiniu.secret_access_key = nil
        end
      end.to raise_error {|err|
        expect( err.message ).to match(/are all required/)
      }
    end

    it 'requires bucket' do
      pre_config = required_config
      expect do
        Storage::Qiniu.new(model) do |qiniu|
          pre_config.call(qiniu)
          qiniu.bucket = nil
        end
      end.to raise_error {|err|
        expect( err.message ).to match(/are all required/)
      }
    end

  end # describe '#initialize'

#  describe '#transfer!' do
#    let(:cloud_io) { mock }
#    let(:timestamp) { Time.now.strftime("%Y.%m.%d.%H.%M.%S") }
#    let(:remote_path) { File.join('my/path/test_trigger', timestamp) }
#
#    before do
#      Timecop.freeze
#      storage.package.time = timestamp
#      storage.package.stubs(:filenames).returns(
#        ['test_trigger.tar-aa', 'test_trigger.tar-ab']
#      )
#      storage.stubs(:cloud_io).returns(cloud_io)
#      storage.bucket = 'my_bucket'
#      storage.path = 'my/path'
#    end
#
#    after { Timecop.return }
#
#    it 'transfers the package files' do
#      src = File.join(Config.tmp_path, 'test_trigger.tar-aa')
#      dest = File.join(remote_path, 'test_trigger.tar-aa')
#
#      Logger.expects(:info).in_sequence(s).with("Storing 'my_bucket/#{ dest }'...")
#      cloud_io.expects(:upload).in_sequence(s).with(src, dest)
#
#      src = File.join(Config.tmp_path, 'test_trigger.tar-ab')
#      dest = File.join(remote_path, 'test_trigger.tar-ab')
#
#      Logger.expects(:info).in_sequence(s).with("Storing 'my_bucket/#{ dest }'...")
#      cloud_io.expects(:upload).in_sequence(s).with(src, dest)
#
#      storage.send(:transfer!)
#    end
#
#  end # describe '#transfer!'

#  describe '#remove!' do
#    let(:cloud_io) { mock }
#    let(:timestamp) { Time.now.strftime("%Y.%m.%d.%H.%M.%S") }
#    let(:remote_path) { File.join('my/path/test_trigger', timestamp) }
#    let(:package) {
#      stub( # loaded from YAML storage file
#        :trigger    => 'test_trigger',
#        :time       => timestamp
#      )
#    }
#
#    before do
#      Timecop.freeze
#      storage.stubs(:cloud_io).returns(cloud_io)
#      storage.bucket = 'my_bucket'
#      storage.path = 'my/path'
#    end
#
#    after { Timecop.return }
#
#    it 'removes the given package from the remote' do
#      Logger.expects(:info).with("Removing backup package dated #{ timestamp }...")
#
#      objects = ['some objects']
#      cloud_io.expects(:objects).with(remote_path).returns(objects)
#      cloud_io.expects(:delete).with(objects)
#
#      storage.send(:remove!, package)
#    end
#
#    it 'raises an error if remote package is missing' do
#      objects = []
#      cloud_io.expects(:objects).with(remote_path).returns(objects)
#      cloud_io.expects(:delete).never
#
#      expect do
#        storage.send(:remove!, package)
#      end.to raise_error(
#        Storage::S3::Error,
#        "Storage::S3::Error: Package at '#{ remote_path }' not found"
#      )
#    end
#
#  end # describe '#remove!'

end
end
