# frozen_string_literal: true

module SolidusKlarna
  module CheckoutControllerDecorator

    def self.prepended(base)
      base.before_action :check_redirect_to_klarna, only: [:update]
    end

    def check_redirect_to_klarna
      return unless (params[:state] == "confirm")
      if @order.last_payment_method.kind_of?(::Spree::PaymentMethod::Klarna)
        redirect_klarna
      end
    end

    private

    def redirect_klarna
      response = ::Spree::KlarnaService.instance.initial_request(@order)
      flash[:error] = response[:error] if response[:error].present?
      redirect_to response[:redirect_url], :status => 302
    end

    ::Spree::CheckoutController.prepend self
  end
end
