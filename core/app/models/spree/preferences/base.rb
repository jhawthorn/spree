# class_attributes are inheritied unless you reassign them in
# the subclass, so when you inherit a Preferable class, the
# inherited hook will assign a new hash for the subclass definitions
# and copy all the definitions allowing the subclass to add
# additional defintions without affecting the base
module Spree::Preferences::Base
  extend ActiveSupport::Concern

  included do
    extend Spree::Preferences::BaseClassMethods
  end

  def get_preference(name)
    has_preference! name
    send self.class.preference_getter_method(name)
  end

  def set_preference(name, value)
    has_preference! name
    send self.class.preference_setter_method(name), value
  end

  def preference_type(name)
    has_preference! name
    send self.class.preference_type_getter_method(name)
  end

  def preference_default(name)
    has_preference! name
    send self.class.preference_default_getter_method(name)
  end

  def has_preference!(name)
    raise NoMethodError.new "#{name} preference not defined" unless has_preference? name
  end

  def has_preference?(name)
    respond_to? self.class.preference_getter_method(name)
  end

  def defined_preferences
    methods.grep(/\Apreferred_.*=\Z/).map do |pref_method|
      pref_method.to_s.gsub(/\Apreferred_|=\Z/, '').to_sym
    end
  end

  def preferences
    Hash[
      defined_preferences.map do |preference|
        [preference, get_preference(preference)]
      end
    ]
  end

  def rails_cache_id
    ENV['RAILS_CACHE_ID']
  end

  def save_pending_preferences
    return unless @pending_preferences
    @pending_preferences.each do |name, value|
      set_preference(name, value)
    end
  end

  def clear_preferences
    preferences.keys.each {|pref| preference_store.delete pref}
  end

  private

  def convert_preference_value(value, type)
    case type
    when :string, :text
      value.to_s
    when :password
      value.to_s
    when :decimal
      BigDecimal.new(value.to_s).round(2, BigDecimal::ROUND_HALF_UP)
    when :integer
      value.to_i
    when :boolean
      if value.is_a?(FalseClass) ||
         value.nil? ||
         value == 0 ||
         value =~ /^(f|false|0)$/i ||
         (value.respond_to? :empty? and value.empty?)
         false
      else
         true
      end
    else
      value
    end
  end

end
