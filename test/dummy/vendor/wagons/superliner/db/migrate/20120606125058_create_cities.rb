superklass = Rails.version >= '5.0' ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration
class CreateCities < superklass
  def change
    create_table :cities do |t|
      t.string :name

      t.timestamps :null => false
    end

    add_column :people, :city_id, :integer
  end
end
