# frozen_string_literal: true

module Spree
  module CheckoutControllerDecorator

    def self.prepended(base)
      base.before_action :check_redirect_to_klarna, only: [:update]
    end

    def check_redirect_to_klarna
      if @order.confirmation_required?
        redirect_klarna_from_confirm_state
      else
        redirect_klarna_from_payment_state
      end
    end

    private

    def redirect_klarna_from_confirm_state
      return unless (params[:state] == "confirm")
      if @order.last_payment_method.kind_of?(::Spree::PaymentMethod::Klarna)
        redirect_klarna
      end
    end

    def redirect_klarna_from_payment_state
      return unless (params[:state] == "payment")
      return unless params[:order][:payments_attributes]
      payment_method = ::Spree::PaymentMethod.find(params[:order][:payments_attributes].first[:payment_method_id])
      if payment_method.kind_of?(::Spree::PaymentMethod::Klarna)
        @order.update_from_params(params, permitted_checkout_attributes)
        redirect_klarna
      end
    end

    def redirect_klarna
      response = ::Spree::KlarnaService.instance.initial_request(@order)
      flash[:error] = response[:error] if response[:error].present?
      redirect_to response[:redirect_url], :status => 302
    end

    ::Spree::CheckoutController.prepend self
  end
end
