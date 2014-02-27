module Spree::Preferences::Preferable
  extend ActiveSupport::Concern
  include Spree::Preferences::Base

  included do
    if respond_to?(:serialize)
      serialize :preference_store, Hash
    end
  end
end

