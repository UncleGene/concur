class CreateDogWithHeadAndLegs < ActiveRecord::Migration
  def change
    create_table :dogs

    create_table :heads do |t|
      t.integer :dog_id
    end
  end

  create_table :legs do |t|
    t.integer :dog_id
  end
end
