class RenameDepositFormRecievedOnCollections < ActiveRecord::Migration[4.2]
  def change
    add_column :collections, :deposit_form_received, :boolean
    remove_column :collections, :deposit_form_recieved
  end
end
