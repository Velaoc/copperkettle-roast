<!-- foundation:identity -->
# Copperkettle Roast

Online store for a small coffee roaster: browse roasts with photos and prices, add to cart, check out, and let signed-in customers review their past orders.

- Site: https://copperkettle-roast.api.holode.xyz
- Support: support@copperkettle-roast.api.holode.xyz
<!-- /foundation:identity -->

## What this is

Online store for a small coffee roaster: browse roasts with photos and prices, add to cart, check out, and let signed-in customers review their past orders.

## Who it is for

- Customers (guest checkout or signed-in; signed-in customers see past orders)
- Shop admin (manage products, view orders)

## Main features

- **Browse catalog** — View roasts with photos, prices, roast level and origin; open a product detail page
- **Cart** — Add products to a cart, adjust quantities, see the running total
- **Checkout** — Check out as guest (email only) or signed-in; order goes through the server-authoritative flow with a receipt
- **Past orders** — Signed-in customers see their order history and order details
- **Admin** — Admin manages products (add, edit, price, photo, availability) and views orders

## Core entities

- Product
- CartItem
- Order
- OrderItem
- Customer

## Included foundation modules

- storefront

## Run locally

```bash
bundle install
bin/rails db:prepare
bin/dev
```

Requires Ruby, PostgreSQL, and the usual Rails toolchain. See `bin/setup` if present.

## Demo

Five roasts (light to dark) with photos, prices, roast level and origin; a sample past order for the demo customer so order history is visible.

## Deploy notes

Production `config.hosts` is derived from `domain` in `config/foundation.yml`. Keep that value aligned with the real host or every request will 403.
