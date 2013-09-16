class CreateSafeNumbers < ActiveRecord::Migration
  def change
    create_table :safe_numbers do |t|
      t.integer :value
    end
    add_index :safe_numbers, :value, unique: true
  end
end
