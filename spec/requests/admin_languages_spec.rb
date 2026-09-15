require 'rails_helper'

# Sources own everything on a Language except its Bounding box, so an admin can audit any row and
# adjust its box, but cannot invent a row or change what the Refresh brings in.
describe 'Admin languages', type: :request do
  let!(:iso) { create(:language, code: 'wbp', name: 'Warlpiri', north_limit: -18.0, south_limit: -24.0, west_limit: 128.0, east_limit: 134.0) }
  let!(:dialect) { create(:language, :glottolog_dialect, code: 'lajo1234', name: 'Lajamanu Warlpiri') }
  let!(:austlang) { create(:language, :austlang, code: 'C15', name: 'Warlpiri', retired: true) }

  before { sign_in create(:user, admin: true) }

  describe 'index' do
    before { get '/admin/languages' }

    it 'shows code, source, name, dialect, retired and whether a box exists' do
      headers = Nokogiri::HTML(response.body).css('table.data-table th').map { |th| th.text.strip }

      expect(headers).to include('Code', 'Source', 'Name', 'Dialect', 'Retired', 'Bounding box')
    end

    it 'marks only the rows with all four limits as having a box' do
      table = Nokogiri::HTML(response.body).at_css('table.data-table')
      headers = table.css('th').map { |th| th.text.strip }
      boxes = table.css('tbody tr').to_h do |tr|
        cells = tr.css('td').map { |td| td.text.strip }
        [cells[headers.index('Code')], cells[headers.index('Bounding box')]]
      end

      expect(boxes).to eq('wbp' => 'Yes', 'lajo1234' => 'No', 'C15' => 'No')
    end

    it 'renders each Source by name' do
      expect(response.body).to include('ISO 639-3', 'Glottolog', 'AUSTLANG')
    end

    it 'filters on source and dialect' do
      expect(response.body).to include('q[source_eq]', 'q[dialect_eq]')
    end

    it 'narrows to one Source' do
      get '/admin/languages', params: { q: { source_eq: 'austlang' } }

      expect(response.body).to include('C15')
      expect(response.body).not_to include('lajo1234', 'wbp')
    end

    it 'offers no way to create a Language' do
      expect(response.body).not_to include('/admin/languages/new')
    end
  end

  describe 'new' do
    it 'is gone' do
      get '/admin/languages/new'

      expect(response).to have_http_status(:not_found)
    end

    it 'refuses a create' do
      expect do
        post '/admin/languages', params: { language: { code: 'zzz', source: 'iso639_3', name: 'Invented' } }
      end.not_to change(Language, :count)
    end

    it 'refuses a destroy' do
      expect { delete "/admin/languages/#{iso.id}" }.not_to change(Language, :count)
    end
  end

  describe 'show' do
    it 'shows the source, dialect and Bounding box' do
      get "/admin/languages/#{dialect.id}"

      rows = Nokogiri::HTML(response.body).css('.attributes-table tr').to_h { |tr| [tr.at_css('th')&.text&.strip, tr.at_css('td')&.text&.strip] }
      expect(rows).to include('Source' => 'Glottolog', 'Dialect' => 'Yes')
      expect(rows.keys).to include('North Limit', 'East Limit', 'South Limit', 'West Limit')
    end
  end

  describe 'edit' do
    it 'offers only the four box limits' do
      get "/admin/languages/#{iso.id}/edit"

      fields = Nokogiri::HTML(response.body).css('form [name^="language["]').map { |input| input['name'] }.uniq
      expect(fields).to contain_exactly('language[north_limit]', 'language[east_limit]', 'language[south_limit]', 'language[west_limit]')
    end
  end

  describe 'update' do
    it 'saves a box change' do
      patch "/admin/languages/#{iso.id}", params: { language: { north_limit: -17.5, south_limit: -25.0, west_limit: 127.0, east_limit: 135.0 } }

      expect(iso.reload).to have_attributes(north_limit: -17.5, south_limit: -25.0, west_limit: 127.0, east_limit: 135.0)
    end

    it 'ignores anything upstream owns' do
      country = create(:country)
      patch "/admin/languages/#{austlang.id}", params: {
        language: {
          code: 'C99', source: 'glottolog', name: 'Renamed', retired: false, dialect: true,
          countries_languages_attributes: { '0' => { country_id: country.id } },
          north_limit: -20.0
        }
      }

      expect(austlang.reload).to have_attributes(code: 'C15', source: 'austlang', name: 'Warlpiri', retired: true, dialect: false, north_limit: -20.0)
      expect(austlang.countries).to be_empty
    end
  end
end
