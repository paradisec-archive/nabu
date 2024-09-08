class CatalogMetadataJob < ApplicationJob
  queue_as :default

  def perform(data, is_item)
    throw 'Moo'
    local_data = { data:, is_item:, admin_rocrate: true }

    rocrate = Api::V1::OniController.render :object_meta, assigns: local_data

    filename = 'ro-crate-metadata.json'

    if is_item
      # data = data.includes(:content_languages, :subject_languages, item_agents: %i[agent_role user])
      Nabu::Catalog.instance.upload_item_admin(data, filename, rocrate, 'application/json')
    else
      # data = data.includes(items: [:admins, :users]) # => { :content_languages, :subject_languages, item_agents: %i[agent_role user] } })
      Nabu::Catalog.instance.upload_collection_admin(data, filename, rocrate, 'application/json')
    end
  end
end
