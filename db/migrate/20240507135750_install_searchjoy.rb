class InstallSearchjoy < ActiveRecord::Migration[7.1]
  def change
    create_table :searchjoy_searches do |t|
      t.references :user
      t.string :search_type
      t.string :query
      t.string :normalized_query
      t.string :search_family
      t.integer :results_count
      t.datetime :created_at
      t.datetime :converted_at
    end

    add_index :searchjoy_searches, [:created_at]
    add_index :searchjoy_searches, %i[search_type created_at]
    add_index :searchjoy_searches, %i[search_type normalized_query created_at], name: 'index_searchjoy_searches_on_search_type_query' # autogenerated name is too long

    create_table :searchjoy_conversions do |t|
      t.references :search
      t.references :convertable, polymorphic: true, index: { name: 'index_searchjoy_conversions_on_convertable' }
      t.datetime :created_at
    end
  end
end
