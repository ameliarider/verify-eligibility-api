class AddStatusToMember < ActiveRecord::Migration[8.0]
  def change
    add_column :members, :active, :boolean
    add_column :members, :terminated_at, :datetime
  end
end
