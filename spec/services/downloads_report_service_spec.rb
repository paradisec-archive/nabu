require 'spec_helper'

describe DownloadsReportService do
  let!(:user) {create(:user)}
  let!(:downloader) {create(:user, country: 'Australia')}

  let!(:collection) {create(:collection)}
  let!(:item) {create(:item, collection: collection, access_condition: AccessCondition.new({name: 'Open (subject to agreeing to PDSC access conditions)'}), collector_id: user.id )}
  let!(:essence) {create(:sound_essence, item: item)}

  let!(:download) { create(:download, essence: essence, user_id: downloader.id) }
  let!(:downloads_report_service_valid_date) { DownloadsReportService.new('21 Jan 2015', '', user) }
  let!(:downloads_report_service_invalid_date) { DownloadsReportService.new('21 Apr 2015', (Time.now - 1.day).strftime('%d %b %Y'), user) }

  context 'with a valid date range' do
    it 'should retrieve the correct joined table' do
      results = downloads_report_service_valid_date.send_report

      expect(results).to eq(1)
    end
  end

  context 'with an invalid date range' do
    it 'should retrieve the correct joined table' do
      results = downloads_report_service_invalid_date.send_report

      expect(results).to eq(0)
    end
  end
end
