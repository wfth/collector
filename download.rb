$LOAD_PATH.unshift(".")

require 'pp'
require 'mechanize'
require 'pg'
require 'json'
require 'aws-sdk'
require 'fileutils'
require 'beachball'
require 'securerandom'

def main
  setup_aws

  puts "Loading messages - #{current_time}"
  puts "\n\n"
  messages_page = agent.get("http://www.wisdomonline.org/media/messages")
  scripture_links = messages_page.search("div#scripture li a")
  agent.keep_alive = false

  scripture_links.each do |scripture|
    puts "#{scripture.text} - #{current_time}"
    puts ""
    scripture_page = agent.click(scripture)
    scripture_pages = scripture_page.search("#copy .pager li a")

    (scripture_pages.empty? ? 1..1 : scripture_pages).each do |page|
      series_collection = scripture_page.search(".series_list > li")

      series_collection.each do |series|
        start_time = Time.now
        puts "#{series_title(series)} - #{current_time}"
        case series_status(series)
        when :incomplete
          series_metadata = compile_series_metadata(series)
          series_id = find_series_id(series_metadata["a_id"], series_metadata["title"])
          delete_series(series_id)
          collect_series_sermons(series, insert_series(series))
        when :nonexistent
          collect_series_sermons(series, insert_series(series))
        end
        puts ""
        puts "#{series_title(series)} took #{Time.at(Time.now - start_time).utc.strftime("%H:%M:%S")}"
        puts ""
      end

      if page != 1
        scripture_page = agent.click(page) if page.text =~ /[1-9]/
      end
    end
  end
end

def current_time
  Time.now.strftime("%d/%m/%y %H:%M")
end

def find_series_id(a_id, title)
  db.exec_params("select id from sermon_series where a_id = $1 or title = $2", [a_id, title]).getvalue(0,0).to_i
end

def delete_series(series_id)
  db.exec_params("delete from sermon_series where id = $1", [series_id])
  sermons = db.exec_params("select * from sermons where sermon_series_id = $1", [series_id])
  sermons.each do |tuple|
    delete_file(tuple["audio_key"])
    delete_file(tuple["transcript_key"])
    delete_file(tuple["buy_graphic_key"])
  end
  db.exec_params("delete from sermons where sermon_series_id = $1", [series_id])
end

def collect_series_sermons(series, series_id)
  return if series_id < 0

  sermons = series.search(".series_links > ul > li")

  sermons.each_with_index do |sermon, index|
    percentage = ((index.to_f / sermons.length) * 100).to_i
    progress_string = "Progress: #{index}/#{sermons.length} (#{percentage}%) "
    print progress_string

    beachball = Beachball.new(10)
    beachball.start

    insert_sermon(sermon, series_id)

    beachball.stop
    print "\b"*(progress_string.length)
  end
end

def series_status(series)
  series_metadata = compile_sermon_metadata(series)
  series_exists = db.exec_params("select * from sermon_series where a_id = $1 or title = $2", [series_metadata["a_id"], series_metadata["title"]]).ntuples > 0

  sermons = series.search(".series_links > ul > li")
  sermons_in_database = []
  sermons.each_with_index do |sermon, index|
    sermon_object = db.exec_params("select * from sermons where title = $1", [sermon_title(sermon)])
    if !sermon_object.ntuples.zero?
      sermons_in_database << sermon_object
    end
  end

  if sermons_in_database.count == sermons.count
    sermons_ratio = 1
  elsif sermons_in_database.count == 0
    sermons_ratio = 0
  elsif sermons_in_database.count < sermons.count
    sermons_ratio = sermons_in_database.count.to_f / sermons.count
  end

  if !series_exists && (sermons_ratio == 0 || sermons_ratio > 0)
    return :nonexistent
  elsif series_exists && sermons_ratio == 1
    return :complete
  elsif series_exists && (sermons_ratio == 0 || sermons_ratio > 0)
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
      connection.exec("CREATE DATABASE collector_dev")
    rescue
    end

    @db = PG.connect(dbname: 'collector_dev', user: "postgres", password: "postgres")

    @db.exec <<-SQL
      create table if not exists sermon_series (
        id SERIAL,
        a_id INTEGER UNIQUE,
        title TEXT NOT NULL,
        description TEXT,
        released_on TEXT,
        passages TEXT,
        graphic_key TEXT,
        graphic_source_url TEXT,
        buy_graphic_key TEXT,
        buy_graphic_source_url TEXT,
        price REAL
      );
    SQL

    @db.exec <<-SQL
      create table if not exists sermons (
        id SERIAL,
        title TEXT NOT NULL,
        description TEXT,
        passage TEXT,
        sermon_series_id INTEGER NOT NULL,
        audio_key TEXT,
        audio_source_url TEXT,
        transcript_key TEXT,
        transcript_source_url TEXT,
        buy_graphic_key TEXT,
        buy_graphic_source_url TEXT,
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
  if !db.exec_params("select id from sermon_series where a_id = $1 or title = $2", [series_metadata["a_id"], series_metadata["title"]]).ntuples.zero?
    puts "found duplicate"
    return -1
  end

  uuid = SecureRandom.uuid

  series_id = db.exec_params("insert into sermon_series (a_id, title, description, released_on, passages) values ($1, $2, $3, $4, $5) returning id",
                             [series_metadata["a_id"],
                              series_metadata["title"],
                              series_metadata["description"],
                              series_metadata["date"],
                              series_metadata["passages"]]).getvalue(0,0).to_i

  graphic_key = upload_series_graphic(series, uuid)
  if graphic_key
    db.exec_params("update sermon_series set graphic_source_url = $1 where id = $2", [series_graphic_source_url(series), series_id])
    db.exec_params("update sermon_series set graphic_key = $1 where id = $2", [graphic_key.to_s, series_id])
  end

  buy_link = series.search(".link-buy-series")[0]
  if buy_link
    buy_page = agent.click(buy_link)

    buy_graphic_key = upload_series_buy_graphic(buy_page, uuid)
    db.exec_params("update sermon_series set buy_graphic_source_url = $1 where id = $2", [series_buy_graphic_source_url(buy_page), series_id])
    db.exec_params("update sermon_series set buy_graphic_key = $1 where id = $2", [buy_graphic_key.to_s, series_id])

    price = get_price(buy_page)
    db.exec_params("update sermon_series set price = $1 where id = $2", [price, series_id])
  end

  return series_id
end

def insert_sermon(sermon, series_id)
  buy_link = sermon.search(".buy_single a")[0]
  if buy_link
    buy_page = agent.click(buy_link)
    sermon_metadata = compile_sermon_metadata(sermon, buy_page)
  else
    sermon_metadata = compile_sermon_metadata(sermon)
  end

  uuid = SecureRandom.uuid

  sermon_id = db.exec_params("insert into sermons (title, description, passage, sermon_series_id) values ($1, $2, $3, $4) returning id",
                             [sermon_metadata["title"],
                              sermon_metadata["description"],
                              sermon_metadata["passage"],
                              series_id]).getvalue(0,0)

  transcript_key = upload_transcript(sermon, uuid)
  if transcript_key
    db.exec_params("update sermons set transcript_source_url = $1 where id = $2", [transcript_source_url(sermon).attr("href"), sermon_id])
    db.exec_params("update sermons set transcript_key = $1 where id = $2", [transcript_key.to_s, sermon_id])
  end

  audio_key = upload_audio(sermon, uuid)
  if audio_key
    db.exec_params("update sermons set audio_source_url = $1 where id = $2", [audio_source_url(sermon).attr("href"), sermon_id])
    db.exec_params("update sermons set audio_key = $1 where id = $2", [audio_key.to_s, sermon_id])
  end

  if buy_link
    buy_graphic_key = upload_sermon_buy_graphic(buy_page, uuid)
    db.exec_params("update sermons set buy_graphic_source_url = $1 where id = $2", [sermon_buy_graphic_source_url(buy_page), sermon_id])
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
    "a_id" => !series.search(".link-buy-series").empty? ? series.search(".link-buy-series").attr("href").text.split("/").last : nil,
    "title" => series.search(".title").text,
    "date" => series.search(".date").text,
    "description" => series.search(".description p").text,
    "passages" => series_passages(series)
  }

  return metadata
end

def series_passages(series)
  series.search(".series_info .scriptures #scripture_refs").text.strip.gsub(/[\n\t]+/, ", ")
end

def compile_sermon_metadata(sermon, buy_page = nil)
  sermon_title = sermon.search(".sermon_title").text[/.+?(?= -)/]
  if sermon_title == nil
    sermon_title = sermon.search(".sermon_title").text[/.+/]
  end

  description = buy_page != nil ? buy_page.search("#copy .product_detail .description p").text : nil

  metadata = {
    "title" => sermon_title,
    "passage" => sermon.search(".sermon_title").text[/(?<=- ).+/],
    "description" => description
  }

  return metadata
end

def transcript_source_url(sermon)
  sermon.search(".transcript a")[0]
end

def audio_source_url(sermon)
  sermon.search(".audio a")[0]
end

def sermon_buy_graphic_source_url(buy_page)
  buy_page.search("#copy .product_detail .product-img img").attr("src")
end

def upload_transcript(sermon, uuid)
  if transcript_source_url(sermon)
    transcript = agent.click(transcript_source_url(sermon))

    tmp_file_path = "/tmp/transcript.pdf"
    transcript.save(tmp_file_path)
    key = upload_file("sermons/#{uuid}/#{transcript.filename}", tmp_file_path)
    FileUtils.rm(tmp_file_path)

    return key
  end
end

def upload_audio(sermon, uuid)
  if audio_source_url(sermon)
    audio = agent.click(audio_source_url(sermon))

    tmp_file_path = "/tmp/audio.mp3"
    audio.save(tmp_file_path)
    key = upload_file("sermons/#{uuid}/#{audio.filename}", tmp_file_path)
    FileUtils.rm(tmp_file_path)

    return key
  end
end

def upload_sermon_buy_graphic(buy_page, uuid)
  buy_graphic_file = agent.get(sermon_buy_graphic_source_url(buy_page))

  tmp_file_path = "/tmp/sermon_buy_graphic.jpg"
  buy_graphic_file.save(tmp_file_path)
  key = upload_file("sermons/#{uuid}/#{buy_graphic_file.filename}", tmp_file_path)
  FileUtils.rm(tmp_file_path)

  return key
end

def series_graphic_source_url(series)
  graphic = series.search(".series_graphic img")[0]
  if graphic
    return graphic.attr("src")
  else
    return nil
  end
end

def series_buy_graphic_source_url(buy_page)
  buy_page.search("#copy .product_detail .product-img img")[0].attr("src")
end

def upload_series_graphic(series, uuid)
  if series_graphic_source_url(series)
    graphic_file = agent.get(series_graphic_source_url(series))

    tmp_file_path = "/tmp/graphic.jpg"
    graphic_file.save(tmp_file_path)
    key = upload_file("sermon_series/#{uuid}/#{graphic_file.filename}", tmp_file_path)
    FileUtils.rm(tmp_file_path)

    return key
  end
end

def upload_series_buy_graphic(buy_page, uuid)
  buy_graphic_file = agent.get(series_buy_graphic_source_url(buy_page))

  tmp_file_path = "/tmp/series_buy_graphic.jpg"
  buy_graphic_file.save(tmp_file_path)
  key = upload_file("sermon_series/#{uuid}/#{buy_graphic_file.filename}", tmp_file_path)
  FileUtils.rm(tmp_file_path)

  return key
end

def get_price(buy_page)
  return buy_page.search(".product_detail .price").text.gsub(/[^0-9\.]/, "").to_f
end

def delete_file(object_key)
  return if object_key == nil
  s3 = Aws::S3::Resource.new(region: 'us-east-1')
  obj = s3.bucket('wisdomonline-development').object(object_key)
  obj.delete
end

def upload_file(object_key, file_path)
  s3 = Aws::S3::Resource.new(region: 'us-east-1')
  obj = s3.bucket('wisdomonline-development').object(object_key)
  obj.acl.put({acl: "public-read"})
  obj_status = obj.upload_file(file_path)

  return obj.key if obj_status
end

main()
