# frozen_string_literal: true

FactoryBot.define do
  factory :klarna_payment_method, class: Spree::PaymentMethod::Klarna do
    name "Klarna payment method"
    type "Spree::PaymentMethod::Klarna"
    active true
  end
end
