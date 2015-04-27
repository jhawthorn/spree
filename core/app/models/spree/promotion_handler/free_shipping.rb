module Spree
  module PromotionHandler
    # Used for activating promotions with shipping rules
    class FreeShipping
      attr_reader :order
      attr_accessor :error, :success

      def initialize(order)
        @order = order
      end

      def activate
        promotions.each do |promotion|
          if promotion.eligible?(order)
            promotion.activate(order: order)
          end
        end
      end

      private

        def promotions
          promo_table = Promotion.arel_table
          code_table  = PromotionCode.arel_table

          promotion_code_condition = promo_table.join(code_table, Arel::Nodes::OuterJoin).on(
            promo_table[:id].eq(code_table[:promotion_id])
          ).join_sources

          Spree::Promotion.
            joins(promotion_code_condition).
            where({
              id: Spree::Promotion::Actions::FreeShipping.pluck(:promotion_id),
              spree_promotion_codes: { id: nil },
              path: nil
            })
        end
    end
  end
end
