$LOAD_PATH.unshift(".")

require 'pp'
require 'mechanize'
require 'pg'
require 'json'
require 'aws-sdk'
require 'fileutils'
require 'beachball'

def main
  setup_aws

  puts "Loading messages"
  messages_page = agent.get("http://www.wisdomonline.org/media/messages")
  scripture_links = messages_page.search("div#scripture li a")

  scripture_links.each do |scripture|
    scripture_page = agent.click(scripture)
    series_collection = scripture_page.search(".series_list > li")

    series_collection.each do |series|
      case series_status(series)
      when :incomplete
        collect_series_sermons(series, find_series_id(series_title(series)))
      when :nonexistent
        collect_series_sermons(series, insert_series(series))
      end
    end
  end
end

def find_series_id(title)
  db.exec_params("select id from sermon_series where title = $1", [title]).getvalue(0,0).to_i
end

def collect_series_sermons(series, series_id)
  puts "Starting a new series"

  sermons = series.search(".series_links > ul > li")

  sermons.each_with_index do |sermon, index|
    if sermon_status(sermon) == :complete
      next
    elsif sermon_status(sermon) == :incomplete
      delete_sermon(sermon)
    end

    percentage = ((index.to_f / sermons.length) * 100).to_i
    print "Progress: #{index}/#{sermons.length} (#{percentage}%) "

    beachball = Beachball.new(10)
    beachball.start

    insert_sermon(sermon, series_id)

    beachball.stop
    print "\b"*22
  end
end

def series_status(series)
  sermons = series.search(".series_links > ul > li")
  sermons.each_with_index do |sermon, index|
    sermon_object = db.exec_params("select * from sermons where title = $1", [sermon_title(sermon)])
    if sermon_object.ntuples == 0
      if index == 0
        return :nonexistent
      else
        return :incomplete
      end
    end
  end

  return :complete
end

def sermon_status(sermon)
  sermon_object = db.exec_params("select audio_key, transcript_key from sermons where title = $1", [sermon_title(sermon)])

  if sermon_object.ntuples == 0
    return :nonexistent
  elsif sermon_object[0]["audio_key"] != nil && sermon_object[0]["transcript_key"] != nil
    return :complete
  else
    return :incomplete
  end
end

def setup_aws
  Aws.config[:credentials] = Aws::Credentials.new(ENV['WFTH_PERMISSIONS_AWS_ACCESS_KEY'], ENV['WFTH_PERMISSIONS_AWS_ACCESS_SECRET'])
end

def agent
  @agent ||= Mechanize.new
end

def db
  unless @db
    initial_connection = PG.connect(user: "postgres", password: "postgres")

    begin
      connection.exec("CREATE DATABASE collector")
    rescue
    end

    @db = PG.connect(dbname: 'collector', user: "postgres", password: "postgres")

    @db.exec <<-SQL
      create table if not exists sermon_series (
        id SERIAL,
        title TEXT NOT NULL,
        description TEXT,
        released_on TEXT,
        graphic_key TEXT,
        buy_graphic_key TEXT,
        price REAL
      );
    SQL

    @db.exec <<-SQL
      create table if not exists sermons (
        id SERIAL,
        title TEXT NOT NULL,
        passage TEXT,
        sermon_series_id INTEGER NOT NULL,
        audio_key TEXT,
        transcript_key TEXT,
        buy_graphic_key TEXT,
        price REAL
      );
    SQL
  end

  return @db
end

def series_title(series)
  series_metadata = compile_series_metadata(series)
  return series_metadata["title"]
end

def sermon_title(sermon)
  sermon_metadata = compile_sermon_metadata(sermon)
  return sermon_metadata["title"]
end

def insert_series(series)
  series_metadata = compile_series_metadata(series)

  series_id = db.exec_params("insert into sermon_series (title, description, released_on) values ($1, $2, $3) returning id",
             [series_metadata["title"],
             series_metadata["description"],
             series_metadata["date"]]).getvalue(0,0).to_i

  graphic_key = upload_series_graphic("series/#{series_id}/graphic.jpg", series)
  db.exec_params("update sermon_series set graphic_key = $1 where id = $2", [graphic_key.to_s, series_id])

  buy_link = series.search(".link-buy-series")[0]
  if buy_link
    buy_page = agent.click(buy_link)

    buy_graphic_key = upload_series_buy_graphic(buy_page, "series/#{series_id}/buy_graphic.jpg")
    db.exec_params("update sermon_series set buy_graphic_key = $1 where id = $2", [buy_graphic_key.to_s, series_id])

    price = get_price(buy_page)
    db.exec_params("update sermon_series set price = $1 where id = $2", [price, series_id])
  end

  return series_id
end

def insert_sermon(sermon, series_id)
  sermon_metadata = compile_sermon_metadata(sermon)

  sermon_id = db.exec_params("insert into sermons (title, passage, sermon_series_id) values ($1, $2, $3) returning id",
             [sermon_metadata["title"],
             sermon_metadata["passage"],
             series_id]).getvalue(0,0)

  transcript_key = upload_transcript("series/#{series_id}/sermons/#{sermon_id}/transcript.pdf", sermon)
  db.exec_params("update sermons set transcript_key = $1 where id = $2", [transcript_key.to_s, sermon_id])

  audio_key = upload_audio("series/#{series_id}/sermons/#{sermon_id}/audio.mp3", sermon)
  db.exec_params("update sermons set audio_key = $1 where id = $2", [audio_key.to_s, sermon_id])

  buy_link = sermon.search(".buy_single a")[0]
  if buy_link
    buy_page = agent.click(buy_link)

    buy_graphic_key = upload_sermon_buy_graphic(buy_page, "series/#{series_id}/sermons/#{sermon_id}/buy_graphic.jpg")
    db.exec_params("update sermons set buy_graphic_key = $1 where id = $2", [buy_graphic_key.to_s, sermon_id])

    price = get_price(buy_page)
    db.exec_params("update sermons set price = $1 where id = $2", [price, sermon_id])
  end
end

def delete_sermon(sermon)
  sermon_metadata = compile_sermon_metadata(sermon)
  db.exec_params("delete from sermons where id = ( select id from sermons where title = $1 order by id limit 1 )", [sermon_metadata["title"].to_s])
end

def compile_series_metadata(series)
  metadata = {
    "title" => series.search(".title").text,
    "date" => series.search(".date").text,
    "description" => series.search(".description p").text
  }

  return metadata
end

def compile_sermon_metadata(sermon)
  sermon_title = sermon.search(".sermon_title").text[/.+?(?= -)/]
  if sermon_title == nil
    sermon_title = sermon.search(".sermon_title").text[/.+/]
  end

  metadata = {
    "title" => sermon_title,
    "passage" => sermon.search(".sermon_title").text[/(?<=- ).+/]
  }

  return metadata
end

def upload_transcript(object_key, sermon)
  transcript_link = sermon.search(".transcript a")[0]
  if transcript_link
    transcript = agent.click(transcript_link)

    tmp_file_path = "/tmp/transcript.pdf"
    transcript.save(tmp_file_path)
    key = upload_file(object_key, tmp_file_path)
    FileUtils.rm(tmp_file_path)

    return key
  end
end

def upload_audio(object_key, sermon)
  audio_link = sermon.search(".audio a")[0]
  if audio_link
    audio = agent.click(audio_link)

    tmp_file_path = "/tmp/audio.mp3"
    audio.save(tmp_file_path)
    key = upload_file(object_key, tmp_file_path)
    FileUtils.rm(tmp_file_path)

    return key
  end
end

def upload_sermon_buy_graphic(buy_page, object_key)
  buy_graphic = buy_page.search("#copy .product_detail .product-img img")
  buy_graphic_file = agent.get(buy_graphic.attribute("src"))

  tmp_file_path = "/tmp/sermon_buy_graphic.jpg"
  buy_graphic_file.save(tmp_file_path)
  key = upload_file(object_key, tmp_file_path)
  FileUtils.rm(tmp_file_path)

  return key
end

def upload_series_graphic(object_key, series)
  graphic = series.search(".series_graphic img")[0]
  if graphic
    graphic_file = agent.get(graphic.attribute("src"))

    tmp_file_path = "/tmp/graphic.jpg"
    graphic_file.save(tmp_file_path)
    key = upload_file(object_key, tmp_file_path)
    FileUtils.rm(tmp_file_path)

    return key
  end
end

def upload_series_buy_graphic(buy_page, object_key)
  buy_graphic = buy_page.search("#copy .product_detail .product-img img")
  buy_graphic_file = agent.get(buy_graphic.attribute("src"))

  tmp_file_path = "/tmp/series_buy_graphic.jpg"
  buy_graphic_file.save(tmp_file_path)
  key = upload_file(object_key, tmp_file_path)
  FileUtils.rm(tmp_file_path)

  return key
end

def get_price(buy_page)
  return buy_page.search(".product_detail .price").text.gsub(/[^0-9\.]/, "").to_f
end

def upload_file(object_key, file_path)
  s3 = Aws::S3::Resource.new(region: 'us-east-1')
  obj = s3.bucket('wisdomonline-development').object(object_key)
  obj_status = obj.upload_file(file_path)

  return obj.key if obj_status
end

main()
