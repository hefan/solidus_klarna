# frozen_string_literal: true

module SolidusKlarna
  module Order
    module KlarnaFeature
      def last_payment_method
        last_payment.try(:payment_method)
      end

      def last_payment
        payments.last
      end

      def klarna_ref_number
        if last_payment_method.present?
          "#{last_payment_method.preferred_reference_prefix}#{number}#{last_payment_method.preferred_reference_suffix}"
        else
          number
        end
      end

      ::Spree::Order.prepend self
    end
  end
end
