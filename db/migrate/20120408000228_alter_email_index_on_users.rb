class AlterEmailIndexOnUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.change :email, :string, :default => nil, :null => true
    end
  end
end
