class CreateValidatedNumbers < ActiveRecord::Migration
  def change
    create_table :validated_numbers do |t|
      t.integer :value
    end
  end
end
