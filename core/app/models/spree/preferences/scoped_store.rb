module Spree::Preferences
  class ScopedStore
    def initialize scope
      @scope = scope
    end
    def store
      Spree::Preferences::Store.instance
    end
    def fetch key, &block
      store.fetch(key_for(key), &block)
    end
    def []= key, value
      store[key_for(key)] = value
    end
    def delete key
      store.delete(key_for(key))
    end
    def key_for key
      [@scope, key].compact.join('_')
    end
  end
end
