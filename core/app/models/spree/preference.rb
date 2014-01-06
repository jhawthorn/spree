class Spree::Preference < ActiveRecord::Base
  serialize :value

  validates :key, presence: true
end
