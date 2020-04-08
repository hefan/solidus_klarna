# frozen_string_literal: true

module Spree
  module OrderDecorator

    def last_payment_method
      last_payment.try(:payment_method)
  	end

  	def last_payment
  		payments.last
  	end

    def klarna_ref_number
  		last_payment_method ? "#{last_payment_method.preferred_reference_prefix}#{number}#{last_payment_method.preferred_reference_suffix}" : number
  	end

    ::Spree::Order.prepend self
  end
end
