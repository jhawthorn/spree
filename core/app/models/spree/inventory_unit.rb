module Spree
  class InventoryUnit < Spree::Base
    belongs_to :shipment, class_name: "Spree::Shipment", touch: true, inverse_of: :inventory_units
    belongs_to :return_authorization, class_name: "Spree::ReturnAuthorization"
    belongs_to :line_item, class_name: "Spree::LineItem", inverse_of: :inventory_units
    def order
      line_item.order
    end

    validate :line_item, :shipment, presence: true

    scope :backordered, -> { where state: 'backordered' }
    scope :shipped, -> { where state: 'shipped' }
    scope :backordered_per_variant, ->(stock_item) do
      includes(:shipment, line_item: :order)
        .where("spree_shipments.state != 'canceled'").references(:shipment)
        .where('spree_line_items.variant_id = ?', stock_item.variant_id)
        .where('spree_orders.completed_at is not null')
        .backordered.order("spree_orders.completed_at ASC")
    end

    # state machine (see http://github.com/pluginaweek/state_machine/tree/master for details)
    state_machine initial: :on_hand do
      event :fill_backorder do
        transition to: :on_hand, from: :backordered
      end

      event :ship do
        transition to: :shipped, if: :allow_ship?
      end

      event :return do
        transition to: :returned, from: :shipped
      end
    end

    # This was refactored from a simpler query because the previous implementation
    # lead to issues once users tried to modify the objects returned. That's due
    # to ActiveRecord `joins(shipment: :stock_location)` only return readonly
    # objects
    #
    # Returns an array of backordered inventory units as per a given stock item
    def self.backordered_for_stock_item(stock_item)
      backordered_per_variant(stock_item).select do |unit|
        unit.shipment.stock_location == stock_item.stock_location
      end
    end

    def self.finalize_units!(inventory_units)
      inventory_units.map do |iu|
        iu.update_columns(
          pending: false,
          updated_at: Time.now,
        )
      end
    end

    def find_stock_item
      Spree::StockItem.where(stock_location_id: shipment.stock_location_id,
        variant_id: line_item.variant_id).first
    end

    # Remove variant default_scope `deleted_at: nil`
    def variant
      Spree::Variant.unscoped { line_item.variant }
    end

    private

      def allow_ship?
        Spree::Config[:allow_backorder_shipping] || self.on_hand?
      end
  end
end

