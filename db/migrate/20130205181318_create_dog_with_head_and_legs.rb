class CreateDogWithHeadAndLegs < ActiveRecord::Migration
  def change
    create_table :dogs

    create_table :heads do |t|
      t.references :dog
    end

    create_table :legs do |t|
      t.references :dog
    end
  end
end
