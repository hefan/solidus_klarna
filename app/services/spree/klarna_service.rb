# frozen_string_literal: true

require 'httparty'

# https://integration.sofort.com/integrationCenter-eng-DE/content/view/full/2513/
module Spree
  class KlarnaService
    include Singleton

    # make the initialization request
    def initial_request(order, ref_number = nil)
      init_data_by_order(order)
      ref_number = @order.klarna_ref_number if ref_number.blank?
      @klarna_payment.update(klarna_hash: build_exit_param)
      raw_response = HTTParty.post(@klarna_payment.payment_method.preferred_server_url,
        headers: header,
        body: initial_request_body(ref_number))

      response = parse_initial_response(raw_response)
      @klarna_payment.update(klarna_transaction: response[:transaction])
      response
    end

    # evaluate transaction status change
    def eval_transaction_status_change(params)
      return if params.blank? || params[:status_notification].blank? || params[:status_notification][:transaction].blank?

      init_data_by_payment(Spree::Payment.find_by(klarna_transaction: params[:status_notification][:transaction]))
      raw_response = HTTParty.post(@klarna_payment.payment_method.preferred_server_url,
        headers: header,
        body: transaction_request_body)
      new_entry = I18n.t("klarna.transaction_status_default")
      if raw_response.parsed_response["transactions"].present? &&
         raw_response.parsed_response["transactions"]["transaction_details"].present?

        td = raw_response.parsed_response["transactions"]["transaction_details"]
        alter_payment_status(td)
        new_entry = "#{td['time']}: #{td['status']} / #{td['status_reason']} (#{td['amount']})"
      end
      old_entries = @klarna_payment.klarna_log || ""
      @klarna_payment.update(klarna_log: old_entries + "#{new_entry}\n")
    end

    private

    def alter_payment_status(transaction_details)
      return if transaction_details["status"].blank?

      if transaction_details["status"] == "loss"
        @klarna_payment.void
      elsif transaction_details["status"] == "pending"
        @klarna_payment.complete
      elsif transaction_details["status"] == "refunded"
        @klarna_payment.void
      else # received
        @klarna_payment.complete
      end
    end

    def init_data_by_order(order)
      raise I18n.t("klarna.no_order_given") if order.blank?

      @order = order

      raise I18n.t("klarna.order_has_no_payment") if @order.last_payment.blank?

      raise I18n.t("klarna.order_has_no_payment_method") if @order.last_payment_method.blank?

      raise I18n.t("klarna.orders_payment_method_is_not_klarna") unless @order.last_payment_method.is_a? Spree::PaymentMethod::Klarna

      init_payment(@order.last_payment)
    end

    def init_data_by_payment(payment)
      raise I18n.t("klarna.no_payment_given") if payment.blank?

      raise I18n.t("klarna.no_payment_method_given") if payment.payment_method.blank?

      raise I18n.t("klarna.wrong_payment_method_given") unless payment.payment_method.is_a? Spree::PaymentMethod::Klarna

      raise I18n.t("klarna.order_not_found") if payment.order.blank?

      @order = payment.order
      init_payment(payment)
    end

    def init_payment(payment)
      @klarna_payment = payment
      @cancel_url = "/checkout/payment"

      raise I18n.t("klarna.config_key_is_blank") if @klarna_payment.payment_method.preferred_config_key.blank?

      config_key_parts = @klarna_payment.payment_method.preferred_config_key.split(":")
      raise I18n.t("klarna.config_key_is_invalid") if config_key_parts.length < 3

      @user_id = config_key_parts[0]
      @project_id = config_key_parts[1]
      @api_key = config_key_parts[2]
      @http_auth_key = "#{@user_id}:#{@api_key}"
    end

    def header
      {
        "Authorization" => "Basic #{Base64.encode64(@http_auth_key)}",
        "Content-Type" => "application/xml; charset=UTF-8",
        "Accept" => "application/xml; charset=UTF-8"
      }
    end

    def initial_request_body(ref_number)
      base_url = "http://#{@order.store.url.split(/\r$/).first}"
      notification_url = "#{base_url}/klarna/status"
      {
        su: {},
        amount: @order.total,
        currency_code: Spree::Config.currency,
        reasons: { reason: ref_number },
        success_url: "#{base_url}/klarna/success?klarna_hash=#{@klarna_payment.klarna_hash}",
        success_link_redirect: "1",
        abort_url: "#{base_url}/klarna/cancel",
        # no url with port as notification url allowed
        notification_urls: { notification_url: notification_url },
        project_id: @project_id
      }.to_xml(dasherize: false, root: 'multipay', root_attrs: { version: '1.0' })
    end

    def transaction_request_body
      { transaction: @klarna_payment.klarna_transaction }.to_xml(dasherize: false, root: 'transaction_request', root_attrs: { version: '2' })
    end

    def parse_initial_response(raw_response)
      response = {}
      if raw_response.parsed_response.blank?
        response[:redirect_url] = @cancel_url
        response[:transaction] = ""
        response[:error] = I18n.t("klarna.unauthorized")
      elsif raw_response.parsed_response["errors"].present?
        response[:redirect_url] = @cancel_url
        response[:transaction] = ""
        all_errors = raw_response.parsed_response["errors"]["error"]
        response[:error] =
          if all_errors.is_a?(Array)
            I18n.t("klarna.error_from_klarna") + ": " + all_errors.map { |e| "#{e['field']}: #{e['message']}" }.join(", ")
          else
            I18n.t("klarna.error_from_klarna") + ": " + all_errors["field"] + ":" + all_errors["message"]
          end
      else
        response[:redirect_url] = raw_response.parsed_response["new_transaction"]["payment_url"]
        response[:transaction] = raw_response.parsed_response["new_transaction"]["transaction"]
      end
      response
    end

    def build_exit_param
      Digest::SHA2.hexdigest(@order.number + @klarna_payment.id.to_s + @klarna_payment.payment_method.preferred_config_key)
    end
  end
end
