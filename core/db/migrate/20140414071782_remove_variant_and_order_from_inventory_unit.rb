class RemoveVariantAndOrderFromInventoryUnit < ActiveRecord::Migration
  def up
    remove_column :spree_inventory_units, :variant_id
    remove_column :spree_inventory_units, :order_id
  end
  def down
  end
end
