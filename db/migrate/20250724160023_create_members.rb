class CreateMembers < ActiveRecord::Migration[8.0]
  def change
    create_table :members do |t|
      t.string :first_name
      t.string :last_name
      t.date :dob
      t.string :external_member_id
      t.string :zip
      t.string :group_number

      t.timestamps
    end
  end
end
