module Spree
  module Api
    class ShipmentsController < Spree::Api::BaseController

      before_filter :find_order
      before_filter :find_and_update_shipment, only: [:ship, :ready, :add, :remove]

      def create
        authorize! :create, Shipment
        variant = Spree::Variant.find(params[:variant_id])
        quantity = params[:quantity].to_i
        @shipment = @order.shipments.create(stock_location_id: params[:stock_location_id])
        @order.contents.add(variant, quantity, nil, @shipment)

        @shipment.refresh_rates
        @shipment.save!

        respond_with(@shipment.reload, default_template: :show)
      end

      def update
        @shipment = find_shipment(params[:id])

        unlock = params[:shipment].delete(:unlock)

        if unlock == 'yes'
          @shipment.adjustment.open
        end

        @shipment.update_attributes(shipment_params)

        if unlock == 'yes'
          @shipment.adjustment.close
        end

        @shipment.reload
        respond_with(@shipment, default_template: :show)
      end

      def ready
        unless @shipment.ready?
          if @shipment.can_ready?
            @shipment.ready!
          else
            render 'spree/api/shipments/cannot_ready_shipment', status: 422 and return
          end
        end
        respond_with(@shipment, default_template: :show)
      end

      def ship
        unless @shipment.shipped?
          @shipment.ship!
        end
        respond_with(@shipment, default_template: :show)
      end

      def add
        variant = Spree::Variant.find(params[:variant_id])
        quantity = params[:quantity].to_i

        @order.contents.add(variant, quantity, nil, @shipment)

        respond_with(@shipment, default_template: :show)
      end

      def remove
        variant = Spree::Variant.find(params[:variant_id])
        quantity = params[:quantity].to_i

        @order.contents.remove(variant, quantity, @shipment)
        @shipment.reload if @shipment.persisted?
        respond_with(@shipment, default_template: :show)
      end

      # Params
      #   :variant_id (required) The variant to transfer
      #   :source_id (required) The source shipment's id
      #   one of (required):
      #     :target_id The shipment to transfer into
      #     :stock_location_id The stock location for a new shipment
      def transfer
        variant = Spree::Variant.find(params[:variant_id])
        quantity = params[:quantity].to_i

        source = find_shipment(params.require(:source_id))
        if params[:target_id].present?
          target = find_shipment(params[:target_id])
        else
          authorize! :create, Shipment
          target = @order.shipments.create!(stock_location_id: params.require(:stock_location_id))
        end

        @order.contents.remove(variant, quantity, source)
        @order.contents.add(variant, quantity, nil, target)

        source.refresh_rates
        target.refresh_rates

        respond_with(@order, default_template: 'spree/api/orders/show')
      end

      private

      def find_order
        @order = Spree::Order.find_by!(number: order_id)
        authorize! :read, @order
      end

      def find_shipment number
        @order.shipments.accessible_by(current_ability, :update).find_by!(number: number)
      end

      def find_and_update_shipment
        @shipment = find_shipment(params[:id])
        @shipment.update_attributes(shipment_params)
        @shipment.reload
      end

      def shipment_params
        if params[:shipment] && !params[:shipment].empty?
          params.require(:shipment).permit(permitted_shipment_attributes)
        else
          {}
        end
      end
    end
  end
end
