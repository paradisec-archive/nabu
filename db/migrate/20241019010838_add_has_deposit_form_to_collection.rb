class AddHasDepositFormToCollection < ActiveRecord::Migration[7.2]
  def change
    add_column :collections, :has_deposit_form, :boolean
  end
end
