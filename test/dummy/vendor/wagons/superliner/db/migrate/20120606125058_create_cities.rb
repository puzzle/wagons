class CreateCities < ActiveRecord::Migration[5.2]
  def change
    create_table :cities do |t|
      t.string :name

      t.timestamps :null => false
    end

    add_column :people, :city_id, :integer
  end
end
