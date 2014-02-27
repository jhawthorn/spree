module Spree::Preferences::Preferable
  extend ActiveSupport::Concern
  include Spree::Preferences::Base

  included do
    if respond_to?(:after_create)
      after_create do |obj|
        obj.save_pending_preferences
      end
    end

    if respond_to?(:after_destroy)
      after_destroy do |obj|
        obj.clear_preferences
      end
    end
  end

  protected
  def preference_store
    if id
      # FIXME: incompatible with previous impl
      Spree::Preferences::ScopedStore.new([rails_cache_id, self.class.name, id].compact.join('::').underscore)
    else
      @pending_preferences ||= {}
    end
  end
end

