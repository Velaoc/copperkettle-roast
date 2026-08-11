# frozen_string_literal: true

module Foundation
  # Optional demo catalog rows (SPEC M10.3).
  #
  # The application boots and serves every page with an empty database, so no
  # seed is ever required. These rows exist only to make the storefront and
  # checkout walkable on a developer machine or in a hosted preview, and they
  # are refused everywhere else — a production deployment must never find
  # invented products in its catalog.
  module DemoSeeds
    PRODUCTS = [
      {
        slug: "ethiopia-yirgacheffe", sku: "COPPER-ETH-YIR",
        name: "Ethiopia Yirgacheffe",
        description: "Single origin, light roast. Washed heirloom lot with jasmine, bergamot, and a sweet lemon finish. 250g bag, whole bean.",
        price_cents: 1_800, position: 0, inventory_quantity: 60,
        roast_level: "Light", origin: "Yirgacheffe, Ethiopia"
      },
      {
        slug: "kenya-aa-nyeri", sku: "COPPER-KEN-AA",
        name: "Kenya AA Nyeri",
        description: "Single origin, light roast. Bright blackcurrant, tomato-bright acidity, and a raw-honey sweetness. 250g bag, whole bean.",
        price_cents: 1_950, position: 1, inventory_quantity: 45,
        roast_level: "Light", origin: "Nyeri, Kenya"
      },
      {
        slug: "colombia-el-paraiso", sku: "COPPER-COL-PAR",
        name: "Colombia El Paraíso",
        description: "Single origin, medium roast. Pink bourbon with red apple, caramel, and dried apricot. 250g bag, whole bean.",
        price_cents: 1_650, position: 2, inventory_quantity: 60,
        roast_level: "Medium", origin: "Huila, Colombia"
      },
      {
        slug: "guatemala-antigua", sku: "COPPER-GUA-ANT",
        name: "Guatemala Antigua",
        description: "Single origin, medium-dark roast. Cocoa nib, toasted hazelnut, and orange zest from the Antigua valley. 250g bag, whole bean.",
        price_cents: 1_700, position: 3, inventory_quantity: 55,
        roast_level: "Medium-dark", origin: "Antigua, Guatemala"
      },
      {
        slug: "sumatra-mandheling", sku: "COPPER-SUM-MAN",
        name: "Sumatra Mandheling",
        description: "Single origin, dark roast. Heavy body with dark chocolate, cedar, and a lingering spice finish. 250g bag, whole bean.",
        price_cents: 1_550, position: 4, inventory_quantity: 55,
        roast_level: "Dark", origin: "Aceh, Sumatra"
      }
    ].freeze

    IMAGE_URLS = {
      "ethiopia-yirgacheffe" => "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=900&q=80",
      "kenya-aa-nyeri" => "https://images.unsplash.com/photo-1521302080334-4bebac2763a6?auto=format&fit=crop&w=900&q=80",
      "colombia-el-paraiso" => "https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=900&q=80",
      "guatemala-antigua" => "https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=900&q=80",
      "sumatra-mandheling" => "https://images.unsplash.com/photo-1447933601403-0c6688de566e?auto=format&fit=crop&w=900&q=80"
    }.freeze

    DEMO_CUSTOMER = {
      email: "ava@example.com",
      password: "copperkettle-demo-1"
    }.freeze

    # Development or a hosted preview only. Preview runs in the production
    # Rails environment, so the preview flag — not RAILS_ENV alone — is what
    # separates a disposable demo from a real deployment.
    def self.permitted?(rails_env: Rails.env, preview: Foundation.preview?)
      rails_env.development? || preview
    end

    def self.run!(io: $stdout)
      unless permitted?
        io.puts("Skipping demo seeds: they are limited to development and hosted previews.")
        return 0
      end

      unless Foundation.storefront_enabled?
        io.puts("Skipping demo seeds: the storefront is disabled in config/foundation.yml.")
        return 0
      end

      created = seed_products!
      customer = seed_customer!(io: io)
      seed_orders!(customer, io: io)
      io.puts("Demo catalog ready: #{PRODUCTS.length} products (#{created} created).")
      created
    end

    # Upserts by slug so repeated runs converge on the same catalog instead of
    # duplicating rows.
    def self.seed_products!
      created = 0

      PRODUCTS.each do |attributes|
        product = Foundation::Storefront::Product.find_or_initialize_by(slug: attributes[:slug])
        created += 1 if product.new_record?
        product.update!(**attributes, currency: "USD", active: true,
          image_url: IMAGE_URLS.fetch(attributes[:slug]))
      end

      created
    end

    # A demo customer with a known password makes order history walkable on
    # first visit to the preview.
    def self.seed_customer!(io:)
      user = User.find_or_initialize_by(email: DEMO_CUSTOMER.fetch(:email))
      if user.new_record?
        user.password = DEMO_CUSTOMER.fetch(:password)
        user.password_confirmation = DEMO_CUSTOMER.fetch(:password)
        user.legal_assent = true
        user.skip_personal_organization = true
        user.save!
        io.puts("Demo customer created: #{DEMO_CUSTOMER.fetch(:email)}")
      end
      user
    end

    # Two past orders at different states so the order history page has
    # something real to show: one fulfilled, one in transit (paid).
    def self.seed_orders!(user, io:)
      return if user.storefront_orders.exists?

      catalog = Foundation::Storefront::Product.order(:position).index_by(&:slug)
      seed_order!(user, catalog, "fulfilled", 21.days.ago,
        [["ethiopia-yirgacheffe", 1], ["colombia-el-paraiso", 2]])
      seed_order!(user, catalog, "paid", 3.days.ago,
        [["sumatra-mandheling", 1], ["kenya-aa-nyeri", 1]])
      io.puts("Demo orders created for #{user.email}.")
    end

    def self.seed_order!(user, catalog, state, created_at, items)
      order = user.storefront_orders.build(
        checkout_key_digest: Digest::SHA256.hexdigest("demo-#{user.id}-#{state}-#{created_at.to_i}"),
        email: user.email,
        state: state,
        currency: "USD",
        subtotal_cents: 0,
        shipping_cents: 0,
        total_cents: 0,
        shipping_method: "standard",
        shipping_name: "Ava Reyes",
        shipping_line1: "212 Harbor Lane",
        shipping_city: "Portland",
        shipping_region: "OR",
        shipping_postal_code: "97201",
        shipping_country: "US",
        terms_version: Foundation::Legal::TERMS_VERSION,
        privacy_version: Foundation::Legal::PRIVACY_VERSION,
        legal_accepted_at: created_at,
        reservation_expires_at: created_at + 45.minutes,
        acceptance_ip: "127.0.0.1",
        acceptance_user_agent: "demo-seed",
        simulated: true
      )
      items.each do |slug, quantity|
        product = catalog.fetch(slug)
        line_total = product.price_cents * quantity
        order.line_items.build(
          product: product,
          name: product.name,
          sku: product.sku,
          unit_price_cents: product.price_cents,
          currency: product.currency,
          quantity: quantity,
          line_total_cents: line_total
        )
        order.subtotal_cents += line_total
        order.total_cents += line_total
      end
      order.save!
      order.update_columns(
        created_at: created_at,
        updated_at: created_at,
        paid_at: state == "paid" ? created_at : nil,
        fulfilled_at: state == "fulfilled" ? created_at : nil,
        checkout_started_at: created_at
      )
      order
    end
    private_class_method :seed_order!
  end
end
