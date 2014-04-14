require 'spec_helper'

module Spree
  describe ShippingCalculator do
    let(:variant1) { build(:variant, :price => 10) }
    let(:variant2) { build(:variant, :price => 20) }

    let(:line_item1) { build(:line_item, variant: variant1) }
    let(:line_item2) { build(:line_item, variant: variant2) }

    let(:package) do
      Stock::Package.new(
        build(:stock_location),
        mock_model(Order, currency: 'USD')
      )
    end

    before do
      package.add line_item1, 2
      package.add line_item2, 1
    end

    subject { ShippingCalculator.new }

    it 'computes with a shipment' do
      shipment = mock_model(Spree::Shipment)
      subject.should_receive(:compute_shipment).with(shipment)
      subject.compute(shipment)
    end

    it 'computes with a package' do
      subject.should_receive(:compute_package).with(package)
      subject.compute(package)
    end

    it 'compute_shipment must be overridden' do
      expect {
        subject.compute_shipment(shipment)
      }.to raise_error
    end

    it 'compute_package must be overridden' do
      expect {
        subject.compute_package(package)
      }.to raise_error
    end

    context 'with no defined currency' do
      it 'is available' do
        subject.available?(package).should be_true
      end
    end
    context 'with matching currency' do
      before{ subject.preferences[:currency] = 'USD' }
      it 'is available' do
        subject.available?(package).should be_true
      end
    end
    context 'with different currency' do
      before{ subject.preferences[:currency] = 'CAD' }
      it 'is available' do
        subject.available?(package).should be_false
      end
    end

    it 'calculates totals for content_items' do
      subject.send(:total, package.contents).should eq 40.00
    end
  end
end
