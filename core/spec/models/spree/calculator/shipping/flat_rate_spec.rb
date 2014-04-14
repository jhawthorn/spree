require 'spec_helper'

module Spree
  module Calculator::Shipping
    describe FlatRate do
      let(:package) do
        Stock::Package.new(
          build(:stock_location),
          mock_model(Order)
        )
      end

      subject { Calculator::Shipping::FlatRate.new(:preferred_amount => 4.00) }

      it 'always returns the same rate' do
        expect(subject.compute(package)).to eql 4.00
      end
    end
  end
end
