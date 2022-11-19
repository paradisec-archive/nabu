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

        expect(printed_output).to include('Checked 1 essence checksum in 1 file. 1 passed | 0 failed')
      end
    end
  end

  context 'with an invalid checksum' do
    describe '.check_checksums_for_files' do
      it 'should check all sums in file and show a failure response only for failed sums' do
        printed_output = capture_stdout do
          ChecksumAnalyserService.check_checksums_for_files([
            { destination_path: Rails.root.join('spec/support/data/checksum/invalid_data/'), file: 'AA3-001-checksum-PDSC_ADMIN.txt' }
          ])
        end

        expect(printed_output).to include('Checked 3 essence checksums in 1 file. 1 passed | 2 failed')
        expect(printed_output).to include('AA3-001-G.wav: FAILED')
        expect(printed_output).to include('AA3-001-X.wav: FAILED')
      end
    end
  end
end
