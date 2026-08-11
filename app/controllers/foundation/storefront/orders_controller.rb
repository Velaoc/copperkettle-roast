# frozen_string_literal: true

module Foundation
  module Storefront
    class OrdersController < BaseController
      def index
        return redirect_to new_user_session_path, alert: "Sign in to view your past orders." unless user_signed_in?

        @orders = current_user.storefront_orders.includes(:line_items).order(created_at: :desc)
        @tokens = @orders.index_with { |order| ReceiptAccess.return_token_for(order) }
      end

      def show
        @order = Order.includes(:line_items).find_by!(public_reference: params[:id])
        head :not_found unless ReceiptAccess.allowed?(order: @order, user: current_user, token: params[:access_token])
      end
    end
  end
end
