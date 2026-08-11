# frozen_string_literal: true

module Foundation
  module Storefront
    # Server-authoritative shipping pricing for Copperkettle Roast.
    #
    # Coffee ships as physical goods. Two methods:
    #   standard       — $4.99, flat, up to 5 business days
    #   roasters-choice — $8.99, flat, 2 business days (the roaster picks the
    #                     carrier and the freshest roast date)
    #
    # Flat-rate on purpose: a small roaster ships from one origin, and flat
    # rates keep the cart honest without a carrier API. Amounts are computed
    # here, never taken from the client.
    class Shipping
      METHODS = {
        "standard" => { cents: 499, label: "Standard (5 business days)" },
        "roasters-choice" => { cents: 899, label: "Roaster's Choice (2 business days)" }
      }.freeze
      DEFAULT_METHOD = "standard"

      def self.cents_for(method)
        METHODS.fetch(method.to_s, METHODS.fetch(DEFAULT_METHOD))[:cents]
      end

      def self.label_for(method)
        METHODS.fetch(method.to_s, METHODS.fetch(DEFAULT_METHOD))[:label]
      end

      def self.valid_method?(method)
        METHODS.key?(method.to_s)
      end
    end
  end
end
