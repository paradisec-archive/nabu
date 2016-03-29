class CreateAdminMessages < ActiveRecord::Migration
  def change
    create_table :admin_messages do |t|
      t.text :message, null: false
      t.datetime :start_at, null: false
      t.datetime :finish_at, null: false

      t.timestamps
    end
  end
end
