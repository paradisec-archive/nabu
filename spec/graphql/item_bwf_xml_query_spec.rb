require 'rails_helper'

describe 'graphql' do
  describe 'item_bwf_xml' do
    let(:user) { create(:user) }
    let(:admin_user) { create(:admin_user) }
    let(:item) { create(:item) }

    let(:query) do
      <<-GRAPHQL
          query GetItemBwfXmlQuery($fullIdentifier: ID!) {
            itemBwfXml(fullIdentifier: $fullIdentifier) {
              fullIdentifier
              itemIdentifier
              collectionIdentifier
              xml
              createdAt
              updatedAt
            }
          }
      GRAPHQL
    end

    context 'when standard user' do
      it 'loads bwf xml' do
        result = NabuSchema.execute(query, variables: { fullIdentifier: item.full_identifier })
        expect(result['errors'].first['message']).to eq('Not authorised')
      end
    end

    context 'when admin' do
      it 'loads bwf xml' do
        result = NabuSchema.execute(query, variables: { fullIdentifier: item.full_identifier },
                                           context: { current_user: admin_user })

        item_result = result['data']['itemBwfXml']
        expect(item_result['itemIdentifier']).to eq(item.identifier)
      end

      it 'Missing item' do
        result = NabuSchema.execute(query, variables: { fullIdentifier: 'FOO-001' },
                                           context: { current_user: admin_user })
        expect(result['errors'].first['message']).to eq('Not found')
      end
    end

    context 'when not logged in' do
      it 'throws an error' do
        result = NabuSchema.execute(query, variables: { fullIdentifier: item.full_identifier })
        expect(result['errors'].first['message']).to eq('Not authorised')
      end
    end
  end
end
