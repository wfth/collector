$LOAD_PATH.unshift(".")

require 'env'
require 'shopify'
require 'sqlite3'
require 'ostruct'

def main
  find_series.each do |series|
    upload_series(series)
  end
end

def db
  @db ||= SQLite3::Database.new("wfth.db")
end

def shop
  @shop ||= ShopifyAPI::Shop.current
end

def upload_series(series)
  new_product = ShopifyAPI::Product.new
  new_product.title = series.title
  new_product.product_type = "Series"
  new_product.handle = product_handle(series.title)
  new_product.body_html = series_body_html(series)
  new_product.variants = [
    ShopifyAPI::Variant.new(
      sku: "series-#{series.id}",
      price: series.price
    )
  ]
  new_product.save

  series.sermons.each do |sermon|
    upload_sermon(series, sermon)
  end
end

def upload_sermon(series, sermon)
  new_product = ShopifyAPI::Product.new
  new_product.title = sermon.title
  new_product.product_type = "Sermon"
  new_product.handle = product_handle(sermon.title)
  new_product.body_html = sermon_body_html(series, sermon)
  new_product.variants = [
    ShopifyAPI::Variant.new(
      sku: "sermon-#{sermon.id}",
      price: sermon.price
    )
  ]
  new_product.save
end

def find_series
  rows = db.execute2("select * from sermon_series")
  columns = rows.shift
  raise "Unexpected columns: #{columns}" unless columns == ["series_id", "title", "description", "released_on", "graphic_key", "buy_graphic_key", "price"]
  rows.map do |row|
    OpenStruct.new(
      id: row[0],
      title: row[1],
      description: row[2],
      price: row[6],
      sermons: find_sermons(row[0])
    )
  end
end

def find_sermons(series_id)
  rows = db.execute2("select * from sermons where sermon_series_id = ?", [series_id])
  columns = rows.shift
  raise "Unexpected columns: #{columns}" unless columns == ["sermon_id", "title", "passage", "sermon_series_id", "audio_key", "transcript_key", "buy_graphic_key", "price"]
  rows.map do |row|
    OpenStruct.new(id: row[0], title: row[1], price: row[7])
  end
end

def product_handle(title)
  title.gsub(/[^A-Za-z0-9]/, '-').gsub(/[-]{2,}/, '-').sub(/-$/, '').downcase
end

def series_body_html(series)
  %Q{<p class="description">#{series.description}</p><p class="series-sermons">Sermons in this series:<ol>#{series_sermons_body_html(series.sermons)}</ol></p>}
end

def series_sermons_body_html(sermons)
  sermons.map do |sermon|
    %Q{<li class="sermon">#{product_link(sermon.title)}</li>}
  end.join("\n")
end

def sermon_body_html(series, sermon)
  %Q{<p class="description">#{sermon.description}</p><p>This sermon is a part of the series #{product_link(series.title)}.</p>}
end

def product_link(title)
  %Q{<a href="#{product_url(title)}">#{title}</a>}
end

def product_url(title)
  "https://#{WFTH_SHOPIFY_SHOP_NAME}.myshopify.com/products/#{product_handle(title)}"
end

main()
