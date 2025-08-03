class CreateEligibilityChecks < ActiveRecord::Migration[8.0]
  def change
    create_table :eligibility_checks do |t|
      t.integer :member_id
      t.boolean :active

      t.timestamps
    end
  end
end
