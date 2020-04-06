# frozen_string_literal: true

Spree::Core::Engine.routes.draw do
  get '/klarna/success', to: 'klarna#success'
  get '/klarna/cancel', to: 'klarna#cancel'
  post '/klarna/status', to: 'klarna#status'
end
