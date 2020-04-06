# frozen_string_literal: true

class Spree::KlarnaController < Spree::StoreController

  skip_before_action :verify_authenticity_token, only: :status

  def success
    klarna_payment = Spree::Payment.find_by(klarna_hash: params[:klarna_hash])

    unless klarna_payment
       flash[:error] = I18n.t("klarna.payment_not_found")
       return redirect_to '/checkout/payment', status: 302
    end

    order = klarna_payment.order
    unless order
     	flash[:error] = I18n.t("klarna.order_not_found")
     	return redirect_to '/checkout/payment', status: 302
    end

    order.next
    if order.complete?
      klarna_payment.capture! if klarna_payment.payment_method.auto_capture?
      session[:order_id] = nil
      flash[:success] = I18n.t("klarna.completed_successfully")
      success_redirect order
    else
      redirect_to checkout_state_path(order.state)
    end
  end

  def cancel
    flash[:error] = I18n.t("klarna.canceled")
    redirect_to '/checkout/payment', status: 302
  end

  def status
    Spree::KlarnaService.instance.eval_transaction_status_change(params)
    head :ok
  end

  private

  def success_redirect order
    redirect_to order_path(order.number, order.guest_token), status: 302
  end

end
