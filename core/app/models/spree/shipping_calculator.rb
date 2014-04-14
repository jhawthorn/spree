module Spree
  class ShippingCalculator < Calculator

    def compute_shipment(shipment)
      raise NotImplementedError, "Please implement 'compute_shipment(shipment)' in your calculator: #{self.class.name}"
    end

    def compute_package(package)
      raise NotImplementedError, "Please implement 'compute_package(package)' in your calculator: #{self.class.name}"
    end

    # Shipping calculators are by default available as long as they share the
    # same currency as the order.
    # Calculators without a currency preference are always available.
    def available?(package)
      preferences[:currency].nil? || preferences[:currency] == package.currency
    end

    private
    def total(content_items)
      content_items.sum { |item| item.quantity * item.variant.price }
    end
  end
end

