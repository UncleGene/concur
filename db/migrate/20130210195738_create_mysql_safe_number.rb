class CreateMysqlSafeNumber < ActiveRecord::Migration
  def change
    create_table :mysql_safe_numbers do |t|
      t.integer :value
    end
    add_index :mysql_safe_numbers, :value, unique: true
  end
end
