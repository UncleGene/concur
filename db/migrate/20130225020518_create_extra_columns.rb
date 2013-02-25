class CreateExtraColumns < ActiveRecord::Migration
  def change
    create_table :extra_columns do |t|
      t.integer :value
    end
  end
end
