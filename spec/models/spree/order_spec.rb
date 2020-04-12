# frozen_string_literal: true

require 'spec_helper'

describe Spree::Order do
  let!(:order) { create(:order) }

  context "when no payment" do
    it "last payment is null" do
      expect(order.last_payment).to eq(nil)
    end

    it "last payment method is null" do
      expect(order.last_payment_method).to eq(nil)
    end

    it "sofort ref number is only order number" do
      expect(order.klarna_ref_number).to eq(order.number)
    end
  end

  context "when valid payment" do
    let!(:payment_method) { create(:klarna_payment_method) }
    let!(:payment) { create(:payment, payment_method: payment_method) }

    it "last payment is given" do
      order.payments << payment
      expect(order.last_payment).not_to eq(nil)
    end

    it "last payment method is given" do
      order.payments << payment
      expect(order.last_payment_method).not_to eq(nil)
    end

    it "klarna ref number has prefix and suffix of payment" do
      order.payments << payment
      pm = order.last_payment_method
      pm.set_preference(:reference_prefix, "prefix")
      pm.set_preference(:reference_suffix, "suffix")
      pm.save!
      expect(order.klarna_ref_number).to eq("prefix#{order.number}suffix")
    end
  end
end
