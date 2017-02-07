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

        printed_output.should include('1/1 checksums succeeded')
      end
    end
  end

  context 'with an invalid checksum' do
    describe '.check_checksums_for_files' do
      it 'should show a failure response' do
        printed_output = capture_stdout do
          ChecksumAnalyserService.check_checksums_for_files([
            { destination_path: Rails.root.join('spec/support/data/checksum/invalid_data/'), file: 'AA3-001-G-checksum-PDSC_ADMIN.txt' }
          ])
        end

        expected_output = "\n0/1 checksums succeeded\n1/1 checksums failed\n"

        printed_output.should match(expected_output)
      end
    end
  end
end
