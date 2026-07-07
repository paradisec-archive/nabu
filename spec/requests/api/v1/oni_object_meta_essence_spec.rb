require 'rails_helper'

# The per-essence RO-Crate (oni#rocrate → object_meta_essence) must derive its
# annotationOf / hasAnnotation links from stored essence_annotations mappings,
# not by inferring relationships from filename basenames at render time.
describe 'Oni essence RO-Crate annotations', :no_catalog_upload, type: :request do
  let(:access_condition) { create(:access_condition, name: 'Open (subject to agreeing to PDSC access conditions)') }
  let(:item) { create(:item, access_condition:) }

  # Guests can never read essences; any signed-in user can read essences on open items.
  before { sign_in create(:user) }

  def rocrate_for(essence)
    id = repository_essence_url(essence.collection, essence.item, essence.filename)
    get "/api/v1/oni/entity/#{CGI.escape(id)}/rocrate"

    expect(response).to have_http_status(:ok)
    response.parsed_body['@graph'].find { |node| node['@id'] == id }
  end

  def essence_id(essence)
    repository_essence_url(essence.collection, essence.item, essence.filename)
  end

  context 'with a stored mapping between files whose basenames differ' do
    let(:media) { create(:sound_essence, item:) }
    let(:transcript) { create(:essence, item:, filename: 'session-transcript.eaf', mimetype: 'text/xml', size: 1_234) }

    before do
      EssenceAnnotation.create!(annotation_essence: transcript, target_essence: media)
    end

    it 'links the transcript to its media via annotationOf' do
      file = rocrate_for(transcript)

      expect(file['annotationOf']).to eq([{ '@id' => essence_id(media) }])
      expect(file).not_to have_key('hasAnnotation')
    end

    it 'links the media back to its transcript via hasAnnotation' do
      file = rocrate_for(media)

      expect(file['hasAnnotation']).to eq([{ '@id' => essence_id(transcript) }])
      expect(file).not_to have_key('annotationOf')
    end
  end

  context 'with matching basenames but no stored mapping' do
    let!(:media) { create(:sound_essence, item:) }
    let!(:transcript) { create(:essence, item:, filename: 'moo.eaf', mimetype: 'text/xml', size: 1_234) }

    before do
      # Ingest auto-links matching basenames; remove the mapping to prove the
      # view reads the table rather than re-inferring from filenames.
      EssenceAnnotation.destroy_all
    end

    it 'emits no annotation links for the transcript' do
      file = rocrate_for(transcript)

      expect(file).not_to have_key('annotationOf')
      expect(file).not_to have_key('hasAnnotation')
    end

    it 'emits no annotation links for the media' do
      file = rocrate_for(media)

      expect(file).not_to have_key('annotationOf')
      expect(file).not_to have_key('hasAnnotation')
    end
  end
end
