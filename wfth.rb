require 'pp'
require 'rubygems'
require 'mechanize'
require 'sqlite3'
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
      status = series_status(series)
      if status == :completed
        next
      elsif status == :unfinished
        series_id = db.execute("select series_id from sermon_series where title = ?", series_title(series)).flatten[0].to_i
      elsif status == :untouched
        series_id = insert_series(series)
      end

      puts "Starting a new series"

      sermons = series.search(".series_links > ul > li")

      sermons.each_with_index do |sermon, index|
        if sermon_completed?(sermon)
          next
        end

        puts "Starting a new sermon"

        percentage = ((index.to_f / sermons.length) * 100).to_i
        print "Progress: #{index}/#{sermons.length} (#{percentage}%) "

        beachball = Beachball.new(10)
        beachball.start

        insert_sermon(sermon, series_id)

        beachball.stop
        print "\b"*22
      end
    end
  end
end

def series_status(series)
  sermons = series.search(".series_links > ul > li")
  sermons.each_with_index do |sermon, index|
    sermon_object = db.execute("select * from sermons where title = ?", sermon_title(sermon)).flatten.first
    if sermon_object == nil
      if index == 0
        return :untouched
      else
        return :unfinished
      end
    end
  end

  return :completed
end

def sermon_completed?(sermon)
  sermon_object = db.execute("select * from sermons where title = ?", sermon_title(sermon)).flatten.first
  if sermon_object != nil
    return true
  else
    return false
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
    @db = SQLite3::Database.new("wfth.db")

    @db.execute <<-SQL
      create table if not exists sermon_series (
        series_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        released_on TEXT,
        graphic_key TEXT
      );
    SQL

    @db.execute <<-SQL
      create table if not exists sermons (
        sermon_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        passage TEXT,
        sermon_series_id INTEGER NOT NULL,
        audio_key TEXT,
        transcript_key TEXT
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

  db.execute("insert into sermon_series (title, description, released_on) values (?, ?, ?)",
             series_metadata["title"],
             series_metadata["description"],
             series_metadata["date"])
  series_id = db.last_insert_row_id

  graphic_key = upload_graphic("series/#{series_id}/graphic.jpg", series)
  db.execute("update sermon_series set graphic_key = '#{graphic_key}' where series_id = #{series_id}")

  return series_id
end

def insert_sermon(sermon, series_id)
  sermon_metadata = compile_sermon_metadata(sermon)

  db.execute("insert into sermons (title, passage, sermon_series_id) values (?, ?, ?)",
             sermon_metadata["title"],
             sermon_metadata["passage"],
             series_id)
  sermon_id = db.last_insert_row_id

  transcript_key = upload_transcript("series/#{series_id}/sermons/#{sermon_id}/transcript.pdf", sermon)
  db.execute("update sermons set transcript_key = '#{transcript_key}' where sermon_id is #{sermon_id}")

  audio_key = upload_audio("series/#{series_id}/sermons/#{sermon_id}/audio.mp3", sermon)
  db.execute("update sermons set audio_key = '#{audio_key}' where sermon_id is #{sermon_id}")
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
  if sermon.search(".transcript a")[0]
    transcript = agent.click(sermon.search(".transcript a")[0])
    transcript.save("/tmp/transcript.pdf")
    key = upload_file(object_key, "/tmp/transcript.pdf")
    FileUtils.rm("/tmp/transcript.pdf")

    return key
  end
end

def upload_audio(object_key, sermon)
  if sermon.search(".audio a")[0]
    audio = agent.click(sermon.search(".audio a")[0])
    audio.save("/tmp/audio.mp3")
    key = upload_file(object_key, "/tmp/audio.mp3")
    FileUtils.rm("/tmp/audio.mp3")

    return key
  end
end

def upload_graphic(object_key, series)
  graphic = series.search(".series_graphic img")[0]
  if graphic
    graphic_file = agent.get(graphic.attribute("src"))
    graphic_file.save("/tmp/graphic.jpg")
    key = upload_file(object_key, "/tmp/graphic.jpg")
    FileUtils.rm("/tmp/graphic.jpg")

    return key
  end
end

def upload_file(object_key, file_path)
  s3 = Aws::S3::Resource.new(region: 'us-east-1')
  obj = s3.bucket('wisdomonline-development').object(object_key)
  obj.upload_file(file_path)

  return obj.key
end

main()
