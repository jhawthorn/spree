module Spree::Preferences
  class ScopedStore
    def initialize prefix, suffix=nil
      @prefix = prefix
      @suffix = suffix
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
      [@prefix, key, @suffix].compact.join('/')
    end
  end
end
