require 'spec_helper'

describe Bosh::Director::Api::TaskManager do
  let(:manager) { described_class.new }

  describe '#decompress' do
    it 'should decompress a .gz file' do
      Dir.mktmpdir do |dir|
        FileUtils.cp(asset('foobar.gz'), dir)
        src = File.join(dir, 'foobar.gz')
        dst = File.join(dir, 'foobar')

        expect(File.exist?(dst)).to be(false)

        manager.decompress(src, dst)

        expect(File.exist?(dst)).to be(true)
      end
    end

    it 'should not decompress if an uncompressed file exist' do
      Dir.mktmpdir do |dir|
        file = File.join(dir, 'file')
        file_gz = File.join(dir, 'file.gz')
        FileUtils.touch(file)
        FileUtils.touch(file_gz)

        expect(File).not_to receive(:open)

        manager.decompress(file_gz, file)
      end
    end
  end

  describe '#task_file' do
    let(:task) { task = double(Bosh::Director::Models::Task) }
    let(:task_dir) { '/var/vcap/store/director/tasks/1' }

    it 'should return the task output contents if the task output contents is not a directory' do
      allow(task).to receive_messages(output: 'task output')

      expect(manager.log_file(task, 'type')).to eq('task output')
    end

    it 'should return the task log path' do
      allow(task).to receive_messages(output: task_dir)
      allow(manager).to receive(:decompress)

      expect(File).to receive(:directory?).with(task_dir).and_return(true)

      manager.log_file(task, 'cpi')
    end
  end
end
