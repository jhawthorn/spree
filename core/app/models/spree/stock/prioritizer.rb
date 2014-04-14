module Spree
  module Stock
    class Prioritizer
      attr_reader :packages, :order

      def initialize(order, packages, adjuster_class=Adjuster)
        @order = order
        @packages = packages
        @adjuster_class = adjuster_class
      end

      def prioritized_packages
        sort_packages
        adjust_packages
        prune_packages
        packages
      end

      private
      def adjust_packages
        # Hash of all adjusters. key is line_item's id
        adjusters = Hash.new do |h, k|
          h[k] ||= @adjuster_class.new(line_item)
        end

        adjuster = @adjuster_class.new(line_item.variant, line_item.quantity)
        packages.each do |package|
          adjuster = adjusters[line_item.id]

          package.contents.each do |item|
            adjuster.adjust(item)
          end
        end

        def sort_packages
          # order packages by preferred stock_locations
        end

        def prune_packages
          packages.reject! { |pkg| pkg.empty? }
        end
      end
    end
  end
