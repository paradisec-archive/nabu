class MakeIdenitfiersCaseSensitive < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL.squish
      ALTER TABLE collections MODIFY identifier VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL;
    SQL
    execute <<-SQL2.squish
      ALTER TABLE items MODIFY identifier VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL;
    SQL2
  end
end
