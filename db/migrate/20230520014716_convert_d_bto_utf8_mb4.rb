class ConvertDBtoUtf8Mb4 < ActiveRecord::Migration[7.0]
  def up
    db = ActiveRecord::Base.connection

    # Fix bad data
    execute "SET sql_mode = ''"
    execute "UPDATE items SET originated_on = NULL WHERE originated_on = '0000-00-00';"

    execute "ALTER DATABASE `#{db.current_database}` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci"

    db.tables.each do |table|
      execute "ALTER TABLE #{table} CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;"
    end
  end
end
