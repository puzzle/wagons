class CreatePeople < ActiveRecord::Migration[5.2]
  def change
    create_table :people do |t|
      t.string :name
      t.date :birthday

      t.timestamps :null => false
    end
  end
end
