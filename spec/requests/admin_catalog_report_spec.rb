require 'rails_helper'

# The report mixes two windows - the selected month (what changed) and everything up to the end of
# that month (archive totals) - and assembles both from grouped queries rather than one query per
# figure. These examples pin that both windows survive the fold-out.
describe 'Admin catalog report', :no_catalog_upload, type: :request do
  let(:collection) { create(:collection, identifier: 'AA1', created_at: '2020-01-01') }
  let(:item) { create(:item, collection: collection, created_at: '2020-01-01') }

  before do
    create(:essence, item: item, filename: 'in-month.wav', mimetype: 'audio/wav', size: 300, duration: 30, created_at: '2020-06-15')
    create(:essence, item: item, filename: 'earlier.jpg', mimetype: 'image/jpeg', size: 50, duration: nil, created_at: '2020-01-15')
    create(:essence, item: item, filename: 'later.mp4', mimetype: 'video/mp4', size: 900, duration: 90, created_at: '2020-12-15')

    sign_in create(:user, admin: true)
    get '/admin/catalog_report', params: { date: { year: 2020, month: 6 } }
  end

  it 'lists only the files added during the selected month' do
    expect(response.body).to include('in-month.wav')
    expect(response.body).not_to include('earlier.jpg')
    expect(response.body).not_to include('later.mp4')
  end

  it 'breaks down file types across the archive as at the end of the selected month' do
    expect(response.body).to include('audio/wav', 'image/jpeg')
    expect(response.body).not_to include('video/mp4')
  end

  it 'reports collection metrics for collections existing as at the end of the selected month' do
    expect(response.body).to include(collection.identifier)
  end
end
