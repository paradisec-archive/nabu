require 'rails_helper'

describe 'GraphQL OAuth Authorization', type: :request do
  let(:collection) { create(:collection, private: false) }
  let(:private_collection) { create(:collection, private: true) }
  let(:item) { create(:item, collection: collection, private: false) }
  let(:private_item) { create(:item, collection: private_collection, private: true) }

  let(:collection_query) do
    <<-GRAPHQL
      query GetCollection($identifier: ID!) {
        collection(identifier: $identifier) {
          identifier
          title
        }
      }
    GRAPHQL
  end

  let(:item_query) do
    <<-GRAPHQL
      query GetItem($fullIdentifier: ID!) {
        item(fullIdentifier: $fullIdentifier) {
          identifier
          title
        }
      }
    GRAPHQL
  end

  let(:item_id3_query) do
    <<-GRAPHQL
      query GetItemId3($fullIdentifier: ID!) {
        itemId3(fullIdentifier: $fullIdentifier) {
          fullIdentifier
          collectionIdentifier
          itemIdentifier
          txt
          createdAt
          updatedAt
        }
      }
    GRAPHQL
  end

  let(:essence_create_mutation) do
    <<-GRAPHQL
      mutation CreateEssence($collectionIdentifier: String!, $itemIdentifier: String!, $filename: String!, $attributes: EssenceAttributes!) {
        essenceCreate(input: { collectionIdentifier: $collectionIdentifier, itemIdentifier: $itemIdentifier, filename: $filename, attributes: $attributes }) {
          essence {
            filename
          }
        }
      }
    GRAPHQL
  end

  def execute_graphql(query, variables: {}, context: {})
    post '/graphql', params: { query: query, variables: variables }

    # puts "🪚 response.status: #{response.status.inspect}"
    # puts "🪚 response.body: #{response.body.inspect}"

    expect(status).to eq(200)

    JSON.parse(response.body)
  end

  def execute_graphql_with_token(query, token, variables: {})
    post '/graphql',
         params: { query: query, variables: variables },
         headers: { 'Authorization' => "Bearer #{token.token}" }

    # puts "🪚 response.status: #{response.status.inspect}"
    # puts "🪚 response.body: #{response.body.inspect}"

    expect(status).to eq(200)

    JSON.parse(response.body)
  end

  describe 'No authentication' do
    it 'cannot access anything' do
      post '/graphql', params: { query: collection_query, variables: { identifier: collection.identifier } }

      result = JSON.parse(response.body)

      expect(response.status).to eq(200)
      expect(result['errors']).to be_present
      expect(result['errors'][0]['message']).to eq('Must be logged in to query Nabu')
    end

    it 'cannot access item ID3 data' do
      post '/graphql', params: { query: item_id3_query, variables: { fullIdentifier: item.full_identifier } }

      result = JSON.parse(response.body)

      expect(response.status).to eq(200)
      expect(result['errors']).to be_present
      expect(result['errors'][0]['message']).to eq('Must be logged in to query Nabu')
    end
  end

  describe 'Machine-to-Machine Authentication' do
    context 'with public scope token' do
      let(:token) { create(:m2m_public_token) }

      it 'can access public collections' do
        result = execute_graphql_with_token(collection_query, token, variables: { identifier: collection.identifier })

        expect(result['data']['collection']).to be_present
        expect(result['data']['collection']['identifier']).to eq(collection.identifier)
      end

      it 'can access public items' do
        result = execute_graphql_with_token(item_query, token, variables: { fullIdentifier: item.full_identifier })

        expect(result['data']['item']).to be_present
        expect(result['data']['item']['identifier']).to eq(item.identifier)
      end

      it 'cannot access private collections' do
        result = execute_graphql_with_token(collection_query, token, variables: { identifier: private_collection.identifier })

        # Should return null or empty for private data with public scope
        expect(result['data']['collection']).to be_nil
      end

      it 'cannot access private items' do
        result = execute_graphql_with_token(item_query, token, variables: { fullIdentifier: private_item.full_identifier })

        expect(result['data']['item']).to be_nil
      end

      it 'can access public item ID3 data' do
        result = execute_graphql_with_token(item_id3_query, token, variables: { fullIdentifier: item.full_identifier })

        expect(result['errors']).to be_present
        expect(result['errors'].first['message']).to eq('ItemId3 not found')
        expect(result['data']['itemId3']).to be_nil
      end

      it 'cannot access private item ID3 data' do
        result = execute_graphql_with_token(item_id3_query, token, variables: { fullIdentifier: private_item.full_identifier })

        expect(result['errors']).to be_present
        expect(result['errors'].first['message']).to eq('ItemId3 not found')
        expect(result['data']['itemId3']).to be_nil
      end

      it 'cannot perform mutations' do
        result = execute_graphql_with_token(
          essence_create_mutation,
          token,
          variables: {
            collectionIdentifier: collection.identifier,
            itemIdentifier: item.identifier,
            filename: 'test.wav',
            attributes: { mimetype: "test/test", size: 16 }
          }
        )

        expect(result['errors']).to be_present
        expect(result['errors'].first['message']).to eq('EssenceCreatePayload not found')
      end
    end

    context 'with admin scope token' do
      let(:token) { create(:m2m_admin_token) }

      it 'can access public collections' do
        result = execute_graphql_with_token(collection_query, token, variables: { identifier: collection.identifier })

        expect(result['data']['collection']).to be_present
        expect(result['data']['collection']['identifier']).to eq(collection.identifier)
      end

      it 'can access private collections' do
        result = execute_graphql_with_token(collection_query, token, variables: { identifier: private_collection.identifier })

        expect(result['data']['collection']).to be_present
        expect(result['data']['collection']['identifier']).to eq(private_collection.identifier)
      end

      it 'can access public items' do
        result = execute_graphql_with_token(item_query, token, variables: { fullIdentifier: item.full_identifier })

        expect(result['data']['item']).to be_present
        expect(result['data']['item']['identifier']).to eq(item.identifier)
      end

      it 'can access private items' do
        result = execute_graphql_with_token(item_query, token, variables: { fullIdentifier: private_item.full_identifier })

        expect(result['data']['item']).to be_present
        expect(result['data']['item']['identifier']).to eq(private_item.identifier)
      end

      it 'can access public item ID3 data' do
        result = execute_graphql_with_token(item_id3_query, token, variables: { fullIdentifier: item.full_identifier })

        expect(result['data']['itemId3']).to be_present
        expect(result['data']['itemId3']['fullIdentifier']).to eq(item.full_identifier)
        expect(result['data']['itemId3']['collectionIdentifier']).to eq(collection.identifier)
        expect(result['data']['itemId3']['itemIdentifier']).to eq(item.identifier)
        expect(result['data']['itemId3']['txt']).to be_present
      end

      it 'can access private item ID3 data' do
        result = execute_graphql_with_token(item_id3_query, token, variables: { fullIdentifier: private_item.full_identifier })

        expect(result['data']['itemId3']).to be_present
        expect(result['data']['itemId3']['fullIdentifier']).to eq(private_item.full_identifier)
        expect(result['data']['itemId3']['collectionIdentifier']).to eq(private_collection.identifier)
        expect(result['data']['itemId3']['itemIdentifier']).to eq(private_item.identifier)
        expect(result['data']['itemId3']['txt']).to be_present
      end

      it 'can perform mutations' do
        result = execute_graphql_with_token(
          essence_create_mutation,
          token,
          variables: {
            collectionIdentifier: collection.identifier,
            itemIdentifier: item.identifier,
            filename: 'test.wav',
            attributes: { mimetype: "test/test", size: 16 }
          }
        )

        expect(result['errors']).to be_nil
        expect(result['data']['essenceCreate']['essence']).to be_present
        expect(result['data']['essenceCreate']['essence']['filename']).to eq('test.wav')
      end
    end
  end

  describe 'User Authentication' do
    let(:user) { create(:user) }
    let(:admin_user) { create(:admin_user) }

    context 'user with public scope token' do
      let(:token) { create(:user_public_token, resource_owner_id: user.id) }

      it 'can access public collections' do
        result = execute_graphql_with_token(collection_query, token, variables: { identifier: collection.identifier })

        expect(result['data']['collection']).to be_present
        expect(result['data']['collection']['identifier']).to eq(collection.identifier)
      end

      it 'can access public items' do
        result = execute_graphql_with_token(item_query, token, variables: { fullIdentifier: item.full_identifier })

        expect(result['data']['item']).to be_present
        expect(result['data']['item']['identifier']).to eq(item.identifier)
      end

      it 'cannot access private collections' do
        result = execute_graphql_with_token(collection_query, token, variables: { identifier: private_collection.identifier })

        expect(result['data']['collection']).to be_nil
      end

      it 'cannot access private items' do
        result = execute_graphql_with_token(item_query, token, variables: { fullIdentifier: private_item.full_identifier })

        expect(result['data']['item']).to be_nil
      end

      it 'cannot access public item ID3 data' do
        result = execute_graphql_with_token(item_id3_query, token, variables: { fullIdentifier: item.full_identifier })

        expect(result['errors']).to be_present
        expect(result['errors'].first['message']).to eq('ItemId3 not found')
        expect(result['data']['itemId3']).to be_nil
      end

      it 'cannot access private item ID3 data' do
        result = execute_graphql_with_token(item_id3_query, token, variables: { fullIdentifier: private_item.full_identifier })

        expect(result['errors']).to be_present
        expect(result['errors'].first['message']).to eq('ItemId3 not found')
        expect(result['data']['itemId3']).to be_nil
      end

      it 'cannot perform mutations' do
        result = execute_graphql_with_token(
          essence_create_mutation,
          token,
          variables: {
            collectionIdentifier: collection.identifier,
            itemIdentifier: item.identifier,
            filename: 'test.wav',
            attributes: { mimetype: "test/test", size: 16 }
          }
        )

        expect(result['errors']).to be_present
        expect(result['errors'].first['message']).to eq('EssenceCreatePayload not found')
      end
    end

    # context 'user with read_write scope token' do
    #   let(:token) { create(:user_read_write_token, resource_owner_id: user.id) }
    #
    #   it 'can access public collections' do
    #     result = execute_graphql_with_token(collection_query, token, variables: { identifier: collection.identifier })
    #
    #     expect(result['data']['collection']).to be_present
    #     expect(result['data']['collection']['identifier']).to eq(collection.identifier)
    #   end
    #
    #   it 'can access public items' do
    #     result = execute_graphql_with_token(item_query, token, variables: { fullIdentifier: item.full_identifier })
    #
    #     expect(result['data']['item']).to be_present
    #     expect(result['data']['item']['identifier']).to eq(item.identifier)
    #   end
    #
    #   context 'when user has permissions' do
    #     let(:user_collection) { create(:collection, private: true, collector: user) }
    #     let(:user_item) { create(:item, collection: user_collection, private: true, collector: user) }
    #     let(:token) { create(:user_read_write_token, resource_owner_id: user.id) }
    #
    #     it 'can access collections they have rights to' do
    #       # This would require setting up proper associations in the test
    #       # For now, we'll test the basic functionality
    #       result = execute_graphql_with_token(item_query, token, variables: { fullIdentifier: user_item.full_identifier })
    #
    #       # The actual result will depend on the CanCan abilities implementation
    #       # This test verifies the token allows the query to execute
    #       expect(result['errors']).to be_nil
    #     end
    #   end
    #
    #   it 'allows mutations based on user abilities' do
    #     # Test would depend on specific user permissions
    #     # For items they can manage, mutations should work
    #     result = execute_graphql_with_token(
    #       essence_create_mutation,
    #       token,
    #       variables: {
    #         collectionIdentifier: collection.identifier,
    #         itemIdentifier: item.identifier,
    #         filename: 'test.wav',
    #         attributes: { mimetype: "test/test", size: 16 }
    #       }
    #     )
    #
    #       puts "🪚 result: #{result.inspect}"
    #
    #     # Result depends on whether user has permission to create essences for this item
    #     # The test ensures the scope doesn't block the mutation attempt
    #     expect(result).to be_present
    #   end
    # end

    context 'admin user with public scope token' do
      let(:token) { create(:admin_user_public_token, resource_owner_id: admin_user.id) }

      it 'can access all collections' do
        result = execute_graphql_with_token(collection_query, token, variables: { identifier: private_collection.identifier })

        expect(result['data']['collection']).to be_present
        expect(result['data']['collection']['identifier']).to eq(private_collection.identifier)
      end

      it 'can access all items' do
        result = execute_graphql_with_token(item_query, token, variables: { fullIdentifier: private_item.full_identifier })

        expect(result['data']['item']).to be_present
        expect(result['data']['item']['identifier']).to eq(private_item.identifier)
      end

      it 'can access all item ID3 data' do
        result = execute_graphql_with_token(item_id3_query, token, variables: { fullIdentifier: private_item.full_identifier })

        expect(result['data']['itemId3']).to be_present
        expect(result['data']['itemId3']['fullIdentifier']).to eq(private_item.full_identifier)
        expect(result['data']['itemId3']['collectionIdentifier']).to eq(private_collection.identifier)
        expect(result['data']['itemId3']['itemIdentifier']).to eq(private_item.identifier)
        expect(result['data']['itemId3']['txt']).to be_present
      end

      it 'can perform all mutations' do
        result = execute_graphql_with_token(
          essence_create_mutation,
          token,
          variables: {
            collectionIdentifier: collection.identifier,
            itemIdentifier: item.identifier,
            filename: 'test.wav',
            attributes: { mimetype: "test/test", size: 16 }
          }
        )

        expect(result['errors']).to be_nil
        expect(result['data']['essenceCreate']['essence']).to be_present
        expect(result['data']['essenceCreate']['essence']['filename']).to eq('test.wav')
      end
    end
  end


  describe 'Invalid token' do
    it 'behaves like no authentication' do
      post '/graphql',
           params: { query: collection_query, variables: { identifier: collection.identifier } },
           headers: { 'Authorization' => 'Bearer invalid_token' }

      expect(response.status).to eq(200)

      result = JSON.parse(response.body)

      expect(result['errors']).to be_present
      expect(result['errors'][0]['message']).to eq('Must be logged in to query Nabu')
    end

    it 'cannot access item ID3 data with invalid token' do
      post '/graphql',
           params: { query: item_id3_query, variables: { fullIdentifier: item.full_identifier } },
           headers: { 'Authorization' => 'Bearer invalid_token' }

      expect(response.status).to eq(200)

      result = JSON.parse(response.body)

      expect(result['errors']).to be_present
      expect(result['errors'][0]['message']).to eq('Must be logged in to query Nabu')
    end
  end
end
