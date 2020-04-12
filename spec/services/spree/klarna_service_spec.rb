# frozen_string_literal: true

require 'spec_helper'

describe Spree::KlarnaService do
  let!(:order) { create(:order_with_line_items) }
  let!(:klarna) { create(:klarna_payment_method) }

  let!(:valid_config_key) { { user_id: "aa", project_id: "bb", api_key: "cc" } }
  let!(:invalid_config_key) { { user_id: "aa", project_id: "bb", api_key: "dd" } }

  let!(:redirect_url) { "http://sofort.com/payhere" }
  let!(:transaction) { "123-456" }

  def valid_auth
    valid_config_key[:user_id] + ":" + valid_config_key[:api_key]
  end

  def invalid_auth
    invalid_config_key[:user_id] + ":" + invalid_config_key[:api_key]
  end

  def valid_config
    valid_config_key[:user_id] + ":" + valid_config_key[:project_id] + ":" + valid_config_key[:api_key]
  end

  def invalid_config
    invalid_config_key[:user_id] + ":" + invalid_config_key[:project_id] + ":" + invalid_config_key[:api_key]
  end

  def stub_initial_request(auth)
    if auth.eql? valid_auth
      # stub_request(:post, "https://#{auth}@api.sofort.com/api/xml")
      stub_request(:post, "https://api.sofort.com/api/xml")
        .to_return(status: 200, headers: { 'Content-Type' => 'application/xml' },
                   body: { payment_url: redirect_url, transaction: transaction }
                     .to_xml(dasherize: false, root: 'new_transaction'))
    else
      # stub_request(:post, "https://#{auth}@api.sofort.com/api/xml")
      stub_request(:post, "https://api.sofort.com/api/xml")
        .to_return(status: 401, headers: { 'Content-Type' => 'application/xml' },
                   body: nil)
    end
  end

  def stub_transaction_request
    stub_request(:post, "https://api.sofort.com/api/xml")
      .to_return(status: 200, headers: { 'Content-Type' => 'application/xml' },
                 body: { transaction_details: { time: "2013-06-03T10:48:52+02:00",
                                                status: "some status",
                                                status_reason: "some reason",
                                                amount: "100.0" } }
                   .to_xml(dasherize: false, root: 'transactions'))
  end

  describe "initial_request" do
    context "when failing" do
      it "raise null order exception" do
        expect {
          described_class.instance.initial_request(nil)
        }.to raise_error(RuntimeError, "no order given")
      end

      it "raises no payment exception" do
        expect {
          described_class.instance.initial_request(order)
        }.to raise_error(RuntimeError, "order has no payment")
      end

      it "raises wrong payment method exception" do
        payment = FactoryBot.create(:payment, payment_method: create(:check_payment_method))
        order.payments = [payment]
        expect {
          described_class.instance.initial_request(order)
        }.to raise_error(RuntimeError, "orders payment method is not #{I18n.t('klarna.name')} payment")
      end

      it "raises blank config key exception" do
        payment = FactoryBot.create(:payment, payment_method: klarna)
        order.payments = [payment]
        expect {
          described_class.instance.initial_request(order)
        }.to raise_error(RuntimeError, "#{I18n.t('klarna.name')} config key is blank")
      end

      it "raises invalid config key exception" do
        klarna.set_preference(:config_key, "something:not3segmented")
        klarna.save!
        payment = FactoryBot.create(:payment, payment_method: klarna)
        order.payments = [payment]
        expect {
          described_class.instance.initial_request(order)
        }.to raise_error(RuntimeError, "#{I18n.t('klarna.name')} config key is invalid")
      end

      it "get unauthorized response without valid klarna merchant key" do
        stub_initial_request invalid_auth
        klarna.set_preference(:config_key, invalid_config)
        klarna.save!
        payment = FactoryBot.create(:payment, payment_method: klarna)
        order.payments = [payment]
        expect(described_class.instance.initial_request(order)[:error]).to eq("Unauthorized")
      end
    end

    context "with success" do
      let!(:kpayment) { create(:payment, payment_method: klarna) }

      before do
        stub_initial_request valid_auth
        klarna.set_preference(:config_key, valid_config)
        klarna.save!
      end

      it "sets the correct klarna_hash" do
        order.payments = [kpayment]
        correct_hash = Digest::SHA2.hexdigest(order.number + kpayment.id.to_s + klarna.preferred_config_key)
        described_class.instance.initial_request(order)
        expect(order.last_payment.klarna_hash).to eq(correct_hash)
      end

      it "gets a redirect url from klarna" do
        order.payments = [kpayment]
        response = described_class.instance.initial_request(order)
        expect(response[:redirect_url]).to eq(redirect_url)
      end

      it "gets a transaction key from klarna" do
        order.payments = [kpayment]
        response = described_class.instance.initial_request(order)
        expect(response[:transaction]).to eq(transaction)
      end

      it "sets the correct transaction key" do
        order.payments = [kpayment]
        described_class.instance.initial_request(order)
        expect(order.last_payment.klarna_transaction).to eq(transaction)
      end
    end
  end

  describe "transaction_status_change" do
    before do
      klarna.set_preference(:config_key, valid_config)
      klarna.save!
      payment = FactoryBot.create(:payment, order: order, payment_method: klarna)
      order.payments << payment
      stub_initial_request valid_auth
      described_class.instance.initial_request(order)
    end

    context "when failing" do
      it "with wrong transaction id" do
        expect {
          described_class.instance.eval_transaction_status_change(status_notification: { transaction: "bogus" })
        }.to raise_error(RuntimeError, "no payment given")
      end
    end

    context "with success" do
      it "logs status change" do
        stub_transaction_request
        described_class.instance.eval_transaction_status_change(status_notification: { transaction: transaction })
        changed_payment = Spree::Payment.find_by(klarna_transaction: transaction)
        expect(changed_payment.klarna_log).to include("some status")
      end
    end
  end
end
