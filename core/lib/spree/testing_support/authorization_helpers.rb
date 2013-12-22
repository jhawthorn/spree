module Spree
  module TestingSupport
    module AuthorizationHelpers
      module Controller
        def stub_authorization!
          before do
            controller.stub :authorize! => true
          end
        end
      end

      module Request
        def stub_authorization!
          custom_authorization! do |user|
            can :manage, :all
          end
        end

        def custom_authorization!(&block)
          ability = Class.new do
            include CanCan::Ability
            define_method(:initialize, block)
          end
          after(:all) do
            Spree::Ability.remove_ability(ability)
          end
          before(:all) do
            Spree::Ability.register_ability(ability)
          end
          before(:each) do
            Spree::Api::Config[:requires_authentication] = false
          end
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.extend Spree::TestingSupport::AuthorizationHelpers::Controller, :type => :controller
  config.extend Spree::TestingSupport::AuthorizationHelpers::Request, :type => :feature
end
