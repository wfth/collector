require 'pp'
require 'rubygems'
require 'mechanize'
require 'sqlite3'
require 'json'
require 'aws-sdk'
require 'fileutils'

# TODO: report progress

$agent = Mechanize.new

def main
  setup_aws
  db = create_db

  messages_page = $agent.get("http://www.wisdomonline.org/media/messages")
  scripture_links = messages_page.search("div#scripture li a")

  for scripture in scripture_links
    scripture_page = $agent.click(scripture)

    for series in scripture_page.search(".series_list > li")
      series_metadata = compile_series_metadata(series)

      db.execute("insert into sermon_series (title, description, released_on) values (?, ?, ?)",
                 series_metadata["title"],
                 series_metadata["description"],
                 series_metadata["date"])
      series_id = `sqlite3 wfth.db "select series_id from sermon_series order by series_id desc limit 1;"`.to_i

      graphic_url = upload_graphic("series/#{series_id}/graphic.jpg", series)
      db.execute("update sermon_series set graphic_url = '#{graphic_url}' where series_id = #{series_id}")

      for sermon in series.search(".series_links > ul > li")
        sermon_metadata = compile_sermon_metadata(sermon)

        db.execute("insert into sermons (title, passage, sermon_series_id) values (?, ?, ?)",
                    sermon_metadata["title"],
                    sermon_metadata["passage"],
                    series_id)
        sermon_id = `sqlite3 wfth.db "select sermon_id from sermons order by sermon_id desc limit 1;"`.to_i

        transcript_url = upload_transcript("series/#{series_id}/sermons/#{sermon_id}/transcript.pdf", sermon)
        db.execute("update sermons set transcript_url = '#{transcript_url}' where sermon_id is #{sermon_id}")
      end
    end
  end
end

def setup_aws
  Aws.config[:credentials] = Aws::Credentials.new(ENV['WFTH_PERMISSIONS_AWS_ACCESS_KEY'], ENV['WFTH_PERMISSIONS_AWS_ACCESS_SECRET'])
end

def upload_file(object_key, file_path)
  s3 = Aws::S3::Resource.new(region: 'us-east-1')
  obj = s3.bucket('wisdomonline-development').object(object_key)
  obj.upload_file(file_path)

  return obj.key
end

def create_db
  `> wfth.db` # Wipe wfth.db of all data, if it exists
  db = SQLite3::Database.new("wfth.db")

  db.execute <<-SQL
    create table sermon_series (
      series_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT,
      released_on TEXT,
      graphic_url TEXT
    );
  SQL

  db.execute <<-SQL
    create table sermons (
      sermon_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      passage TEXT,
      sermon_series_id INTEGER NOT NULL,
      audio_url TEXT,
      transcript_url TEXT
    );
  SQL

  return db
end

def upload_transcript(object_key, sermon)
  if sermon.search(".transcript a")[0]
    transcript = $agent.click(sermon.search(".transcript a")[0])
    transcript.save("/tmp/transcript.pdf")
    key = upload_file(object_key, "/tmp/transcript.pdf")
    FileUtils.rm("/tmp/transcript.pdf")

    return key
  end
end

# TODO: upload audio to S3 and return url

# def download_audio(sermon, path)
#   if sermon.search(".audio a")[0]
#     audio = $agent.click(sermon.search(".audio a")[0])
#     audio.save(path + "/Audio.mp3")
#   end
# end

def upload_graphic(object_key, series)
  graphic = series.search(".series_graphic img")[0]
  if graphic
    graphic_file = $agent.get(graphic.attribute("src"))
    graphic_file.save("/tmp/graphic.jpg")
    key = upload_file(object_key, "/tmp/graphic.jpg")
    FileUtils.rm("/tmp/graphic.jpg")

    return key
  end
end

def compile_series_metadata(series)
  metadata = {
    "title" => series.search(".title").text,
    "date" => series.search(".date").text,
    "description" => series.search(".description p").text
  }

  if series.search(".link-buy-series")[0]
    metadata["buy_link"] = series.search(".link-buy-series")[0].attributes["href"].text
  end

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

  if sermon.search(".buy_single a")[0]
    metadata["buy_link"] = sermon.search(".buy_single a").attribute("href").text
  end

  return metadata
end

main()
