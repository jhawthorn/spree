module Spree
  class Promotion
    module Actions
      class CreateItemAdjustments < PromotionAction
        include Spree::Core::CalculatedAdjustments

        has_many :adjustments, as: :source

        delegate :eligible?, to: :promotion

        before_validation :ensure_action_has_calculator
        before_destroy :deals_with_adjustments

        def perform(payload = {})
          order = payload[:order]
          promotion = payload[:promotion]
          promotion_code = payload[:promotion_code]

          result = false

          line_items_to_adjust(promotion, order).each do |line_item|
            current_result = self.create_adjustment(line_item, order, promotion_code)
            result ||= current_result
          end
          return result
        end

        def create_adjustment(adjustable, order, promotion_code)
          amount = self.compute_amount(adjustable)
          return if amount == 0
          self.adjustments.create!(
            amount: amount,
            adjustable: adjustable,
            order: order,
            promotion_code: promotion_code,
            label: "#{Spree.t(:promotion)} (#{promotion.name})",
          )
          true
        end

        # Ensure a negative amount which does not exceed the sum of the order's
        # item_total and ship_total
        def compute_amount(adjustable)
          promotion_amount = self.calculator.compute(adjustable).to_f.abs
          [adjustable.amount, promotion_amount].min * -1
        end

        private
          # Tells us if there if the specified promotion is already associated with the line item
          # regardless of whether or not its currently eligible. Useful because generally
          # you would only want a promotion action to apply to line item no more than once.
          #
          # Receives an adjustment +source+ (here a PromotionAction object) and tells
          # if the order has adjustments from that already
          def promotion_credit_exists?(adjustable)
            self.adjustments.where(:adjustable_id => adjustable.id).exists?
          end

          def ensure_action_has_calculator
            return if self.calculator
            self.calculator = Calculator::PercentOnLineItem.new
          end

          def deals_with_adjustments
            adjustment_scope = self.adjustments.includes(:order).references(:spree_orders)

            # For incomplete orders, remove the adjustment completely.
            adjustment_scope.where("spree_orders.completed_at IS NULL").each do |adjustment|
              adjustment.destroy
            end

            # For complete orders, the source will be invalid.
            # Therefore we nullify the source_id, leaving the adjustment in place.
            # This would mean that the order's total is not altered at all.
            adjustment_scope.where("spree_orders.completed_at IS NOT NULL").each do |adjustment|
              adjustment.update_columns(
                source_id: nil,
                updated_at: Time.now,
              )
            end
          end

          def line_items_to_adjust(promotion, order)
            excluded_ids = self.adjustments.pluck(:adjustable_id)
            order.line_items.where.not(id: excluded_ids).select do |line_item|
              promotion.line_item_actionable? order, line_item
            end
          end
      end
    end
  end
end
