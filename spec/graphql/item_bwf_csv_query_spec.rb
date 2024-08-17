require 'rails_helper'

describe 'graphql' do
  describe 'item_bwf_csv' do
    let(:user) { create(:user) }
    let(:admin_user) { create(:admin_user) }
    let(:item) { create(:item) }

    let(:query) do
      <<-GRAPHQL
          query GetItemBwfCsvQuery($filename: String!, $fullIdentifier: ID!) {
            itemBwfCsv(filename: $filename, fullIdentifier: $fullIdentifier) {
              fullIdentifier
              itemIdentifier
              collectionIdentifier
              csv
              createdAt
              updatedAt
            }
          }
      GRAPHQL
    end

    context 'when standard user' do
      it 'loads bwf csv' do
        result = NabuSchema.execute(query, variables: { fullIdentifier: item.full_identifier, filename: 'file.wav' })
        expect(result['errors'].first['message']).to eq('Not authorised')
      end
    end

    context 'when admin' do
      it 'loads bwf csv' do
        result = NabuSchema.execute(query, variables: { fullIdentifier: item.full_identifier, filename: 'file.wav' },
                                           context: { admin_authenticated: true })

        item_result = result['data']['itemBwfCsv']
        expect(item_result['itemIdentifier']).to eq(item.identifier)
      end

      it 'Missing item' do
        result = NabuSchema.execute(query, variables: { fullIdentifier: 'FOO-001', filename: 'file.wav' },
                                           context: { admin_authenticated: true })
        expect(result['errors'].first['message']).to eq('Not found')
      end
    end

    context 'when not logged in' do
      it 'throws an error' do
        result = NabuSchema.execute(query, variables: { fullIdentifier: item.full_identifier, filename: 'file.wav' })
        expect(result['errors'].first['message']).to eq('Not authorised')
      end
    end
  end
end
