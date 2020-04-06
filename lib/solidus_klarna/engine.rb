# frozen_string_literal: true

require 'spree/core'
require 'solidus_klarna'

module SolidusKlarna
  class Engine < Rails::Engine
    include SolidusSupport::EngineExtensions::Decorators

    isolate_namespace ::Spree

    engine_name 'solidus_klarna'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    initializer "spree.payment_method.add_klarna", after: "spree.register.payment_methods" do |app|
      app.config.spree.payment_methods << Spree::PaymentMethod::Klarna
    end
  end
end
