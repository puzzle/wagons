superklass = Rails.version >= '5.0' ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration
class CreatePeople < superklass
  def change
    create_table :people do |t|
      t.string :name
      t.date :birthday

      t.timestamps :null => false
    end
  end
end
