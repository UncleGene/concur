class AddExtraColumn < ActiveRecord::Migration
  def change
    add_column :extra_columns, :extra, :string
  end
end
