require 'shopify_api'

shop_url = "https://#{WFTH_PERMISSIONS_SHOPIFY_COLLECTOR_API_KEY}:#{WFTH_PERMISSIONS_SHOPIFY_COLLECTOR_PASSWORD}@#{WFTH_SHOPIFY_SHOP_NAME}.myshopify.com/admin"
ShopifyAPI::Base.site = shop_url
