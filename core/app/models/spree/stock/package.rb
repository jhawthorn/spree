module Spree
  module Stock
    class Package
      ContentItem = Struct.new(:line_item, :quantity, :state) do
        delegate :variant, to: :line_item
      end

      attr_reader :stock_location, :order, :contents
      attr_accessor :shipping_rates

      delegate :currency, to: :order

      def initialize(stock_location, order, contents=[])
        @stock_location = stock_location
        @order = order
        @contents = contents
        @shipping_rates = Array.new
      end

      def add(line_item, quantity, state = :on_hand)
        contents << ContentItem.new(line_item, quantity, state)
      end

      def weight
        contents.sum { |item| item.variant.weight * item.quantity }
      end

      def on_hand
        contents.select { |item| item.state == :on_hand }
      end

      def backordered
        contents.select { |item| item.state == :backordered }
      end

      def quantity(state=nil)
        case state
        when :on_hand
          on_hand.sum { |item| item.quantity }
        when :backordered
          backordered.sum { |item| item.quantity }
        else
          contents.sum { |item| item.quantity }
        end
      end

      def empty?
        quantity == 0
      end

      def shipping_categories
        contents.map { |item| item.variant.shipping_category }.compact.uniq
      end

      def shipping_methods
        shipping_categories.map(&:shipping_methods).reduce(:&).to_a
      end

      def inspect
        out = "#{order} - "
        out << contents.map do |content_item|
          "#{content_item.variant.name} #{content_item.quantity} #{content_item.state}"
        end.join('/')
        out
      end

      def to_shipment
        shipment = Spree::Shipment.new
        shipment.order = order
        shipment.stock_location = stock_location
        shipment.shipping_rates = shipping_rates

        contents.each do |item|
          item.quantity.times do |n|
            unit = shipment.inventory_units.build
            unit.pending = true
            unit.order = order
            unit.line_item = item.line_item
            unit.state = item.state.to_s
          end
        end

        shipment
      end
    end
  end
end
