class AddPreferenceStoreToEverything < ActiveRecord::Migration
  def change
    add_column :spree_calculators, :preference_store, :text
    add_column :spree_gateways, :preference_store, :text
    add_column :spree_payment_methods, :preference_store, :text
    add_column :spree_promotion_rules, :preference_store, :text
  end
end
