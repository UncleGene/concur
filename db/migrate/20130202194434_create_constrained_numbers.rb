class CreateConstrainedNumbers < ActiveRecord::Migration
  def change
    create_table :constrained_numbers do |t|
      t.integer :value
    end
    add_index :constrained_numbers, :value, unique: true
  end
end
