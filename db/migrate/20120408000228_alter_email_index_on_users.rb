class AlterEmailIndexOnUsers < ActiveRecord::Migration[4.2]
  def change
    change_table :users do |t|
      t.change :email, :string, :default => nil, :null => true
    end
  end
end
