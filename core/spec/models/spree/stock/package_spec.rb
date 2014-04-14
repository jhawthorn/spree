require 'spec_helper'

module Spree
  module Stock
    describe Package do
      let(:variant) { build(:variant, weight: 25.0) }
      let(:line_item) { build(:line_item, variant: variant) }
      let(:stock_location) { build(:stock_location) }
      let(:order) { build(:order) }

      subject { Package.new(stock_location, order) }

      it 'calculates the weight of all the contents' do
        subject.add line_item, 4
        subject.weight.should == 100.0
      end

      it 'filters by on_hand and backordered' do
        subject.add line_item, 4, :on_hand
        subject.add line_item, 3, :backordered
        subject.on_hand.count.should eq 1
        subject.backordered.count.should eq 1
      end

      it 'calculates the quantity by state' do
        subject.add line_item, 4, :on_hand
        subject.add line_item, 3, :backordered

        subject.quantity.should eq 7
        subject.quantity(:on_hand).should eq 4
        subject.quantity(:backordered).should eq 3
      end

      it 'returns nil for content item not found' do
        item = subject.find_item(variant, :on_hand)
        item.should be_nil
      end

      it 'finds content item for a variant' do
        subject.add line_item, 4, :on_hand
        item = subject.find_item(variant, :on_hand)
        item.quantity.should eq 4
      end

      # Contains regression test for #2804
      it 'builds a list of shipping methods common to all categories' do
        category1 = create(:shipping_category)
        category2 = create(:shipping_category)
        method1   = create(:shipping_method)
        method2   = create(:shipping_method)
        method1.shipping_categories = [category1, category2]
        method2.shipping_categories = [category1]
        variants = [
          mock_model(Variant, shipping_category: category1),
          mock_model(Variant, shipping_category: category2),
          mock_model(Variant, shipping_category: nil)
        ]
        line_items = variants.map do |variant|
          mock_model(LineItem, variant: variant)
        end

        package = Package.new(stock_location, order)
        package.add line_items[0], 2
        package.add line_items[1], 1
        package.add line_items[2], 1
        package.shipping_methods.should == [method1]
      end

      it 'builds an empty list of shipping methods when no categories' do
        variant  = mock_model(Variant, shipping_category: nil)
        package  = Package.new(stock_location, order)
        package.add line_item, 1
        package.shipping_methods.should be_empty
      end

      it "can convert to a shipment" do
        subject.add line_item, 2, :on_hand
        subject.add line_item, 1, :backordered

        shipping_method = build(:shipping_method)
        subject.shipping_rates = [ Spree::ShippingRate.new(shipping_method: shipping_method, cost: 10.00, selected: true) ]

        shipment = subject.to_shipment
        shipment.order.should == subject.order
        shipment.stock_location.should == subject.stock_location
        shipment.inventory_units.size.should == 3

        first_unit = shipment.inventory_units.first
        first_unit.variant.should == variant
        first_unit.state.should == 'on_hand'
        first_unit.order.should == subject.order
        first_unit.should be_pending

        last_unit = shipment.inventory_units.last
        last_unit.variant.should == variant
        last_unit.state.should == 'backordered'
        last_unit.order.should == subject.order

        shipment.shipping_method.should eq shipping_method
      end
    end
  end
end
