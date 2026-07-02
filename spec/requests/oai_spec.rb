require 'rails_helper'

# The OAI providers advertise a narrow set of metadata formats (collections: oai_dc + rif,
# items: oai_dc + olac) by overriding `.formats`. The oai gem's own format lookup reads the
# global format registry, so a format registered by the *other* provider used to leak through:
# requesting olac on /oai/collection reached the encoder for a model with no to_olac and a
# format with no fields, raising `undefined method 'each' for nil` -> HTTP 500 (NABU-P1).
# A format that is not registered at all (garbage) was always rejected correctly.
describe 'OAI-PMH metadata formats', :no_catalog_upload, type: :request do
  describe 'GET /oai/collection' do
    before { create(:collection) } # public by default; gives ListRecords a record to encode

    it 'serves the advertised oai_dc format' do
      get '/oai/collection', params: { verb: 'ListRecords', metadataPrefix: 'oai_dc' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<ListRecords>')
    end

    it 'rejects the item-only olac format with cannotDisseminateFormat instead of a 500' do
      get '/oai/collection', params: { verb: 'ListRecords', metadataPrefix: 'olac' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('code="cannotDisseminateFormat"')
    end
  end

  describe 'GET /oai/item' do
    before { create(:item) }

    it 'rejects the collection-only rif format with cannotDisseminateFormat instead of a 500' do
      get '/oai/item', params: { verb: 'ListRecords', metadataPrefix: 'rif' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('code="cannotDisseminateFormat"')
    end
  end
end
