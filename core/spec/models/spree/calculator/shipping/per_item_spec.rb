require 'spec_helper'

module Spree
  module Calculator::Shipping
    describe PerItem do
      let(:variant1) { build(:variant) }
      let(:variant2) { build(:variant) }

      let(:line_item1) { build(:line_item, variant: variant1) }
      let(:line_item2) { build(:line_item, variant: variant2) }

      let(:package) do
        Stock::Package.new(
          build(:stock_location),
          mock_model(Order)
        )
      end

      before do
        package.add line_item1, 5
        package.add line_item1, 3
      end

      subject { PerItem.new(:preferred_amount => 10) }

      it "correctly calculates per item shipping" do
        subject.compute(package).to_f.should == 80 # 5 x 10 + 3 x 10
      end
    end
  end
end
