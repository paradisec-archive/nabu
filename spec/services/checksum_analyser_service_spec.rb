require 'spec_helper'

describe ChecksumAnalyserService do
  context 'with a valid checksum and file' do
    describe '.check_checksums_for_files' do
      it 'should show a success response' do
        printed_output = capture_stdout do
          ChecksumAnalyserService.check_checksums_for_files([
            { destination_path: Rails.root.join('spec/support/data/checksum/valid_data/'), file: 'AA3-001-G-checksum-PDSC_ADMIN.txt' }
          ])
        end

        expected_output = "checking checksums...\n---------------------------------------------------------------\nchecking checksum for /Users/stanislavbelkov/Terem/nabu/spec/support/data/checksum/valid_data/AA3-001-G-checksum-PDSC_ADMIN.txt\n/Users/stanislavbelkov/Terem/nabu/spec/support/data/checksum/valid_data/AA3-001-G.wav: OK\n---------------------------------------------------------------\n1 .txt checksum files were checked\n---------------------------------------------------------------\n1/1 checksums succeeded\n0/1 checksums failed\n"

        printed_output.should eq(expected_output)
      end
    end

    context 'with a corrupted sound file' do
      it 'should show a failure response' do
        printed_output = capture_stdout do
          ChecksumAnalyserService.check_checksums_for_files([
            { destination_path: Rails.root.join('spec/support/data/checksum/invalid_data/'), file: 'AA3-001-G-checksum-PDSC_ADMIN.txt' }
          ])
        end

        expected_output = "checking checksums...\n---------------------------------------------------------------\nchecking checksum for /Users/stanislavbelkov/Terem/nabu/spec/support/data/checksum/invalid_data/AA3-001-G-checksum-PDSC_ADMIN.txt\n/Users/stanislavbelkov/Terem/nabu/spec/support/data/checksum/invalid_data/AA3-001-G.wav: FAILED\n/Users/stanislavbelkov/Terem/nabu/spec/support/data/checksum/invalid_data/md5sum: WARNING: 1 of 1 computed checksums did NOT match\n---------------------------------------------------------------\n1 .txt checksum files were checked\n---------------------------------------------------------------\n0/1 checksums succeeded\n1/1 checksums failed\n"

        printed_output.should eq(expected_output)
      end
    end
  end
end
