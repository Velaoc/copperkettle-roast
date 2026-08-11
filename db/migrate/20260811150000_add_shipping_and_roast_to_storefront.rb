class AddShippingAndRoastToStorefront < ActiveRecord::Migration[8.1]
  def change
    # Physical-goods fulfillment: coffee roasts ship, so orders carry a
    # shipping address and a shipping line. Totals become subtotal + shipping
    # (the existing subtotal = total check constraint is dropped and replaced
    # below so totals can include shipping).
    change_table :storefront_orders do |t|
      t.string :shipping_name
      t.string :shipping_line1
      t.string :shipping_line2
      t.string :shipping_city
      t.string :shipping_region
      t.string :shipping_postal_code
      t.string :shipping_country, limit: 2
      t.string :shipping_method, null: false, default: "standard"
      t.bigint :shipping_cents, null: false, default: 0
      t.datetime :shipped_at
    end

    # Roast catalog metadata for the coffee storefront.
    change_table :storefront_products do |t|
      t.string :roast_level
      t.string :origin
      t.integer :weight_grams
    end

    reversible do |dir|
      dir.up do
        execute <<~SQL
          ALTER TABLE storefront_orders
            DROP CONSTRAINT IF EXISTS storefront_orders_total_matches_subtotal,
            ADD CONSTRAINT storefront_orders_total_matches_items
              CHECK (total_cents = subtotal_cents + shipping_cents),
            ADD CONSTRAINT storefront_orders_shipping_nonnegative
              CHECK (shipping_cents >= 0),
            ADD CONSTRAINT storefront_orders_shipping_country_format
              CHECK (shipping_country IS NULL OR (shipping_country ~ '^[A-Z]{2}$')),
            ADD CONSTRAINT storefront_orders_shipping_method_allowed
              CHECK (shipping_method IN ('standard', 'roasters-choice'));
        SQL
      end
      dir.down do
        execute <<~SQL
          ALTER TABLE storefront_orders
            DROP CONSTRAINT IF EXISTS storefront_orders_total_matches_items,
            DROP CONSTRAINT IF EXISTS storefront_orders_shipping_nonnegative,
            DROP CONSTRAINT IF EXISTS storefront_orders_shipping_country_format,
            DROP CONSTRAINT IF EXISTS storefront_orders_shipping_method_allowed,
            ADD CONSTRAINT storefront_orders_total_matches_subtotal
              CHECK (subtotal_cents = total_cents);
        SQL
      end
    end
  end
end
