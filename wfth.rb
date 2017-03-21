require 'pp'
require 'rubygems'
require 'mechanize'
require 'sqlite3'
require 'json'

# TODO: report progress

$agent = Mechanize.new

def main
  db = SQLite3::Database.new("wfth.db")
  create_db_tables(db)

  messages_page = $agent.get("http://www.wisdomonline.org/media/messages")
  scripture_links = messages_page.search("div#scripture li a")

  for scripture in scripture_links
    scripture_page = $agent.click(scripture)

    for series in scripture_page.search(".series_list > li")
      series_metadata = compile_series_metadata(series)

      db.execute("insert into sermon_series (title, description, released_on, graphic_url) values (?, ?, ?, ?)",
                 series_metadata["title"],
                 series_metadata["description"],
                 series_metadata["date"],
                 "nothing right now")
      series_id = `sqlite3 wfth.db "select series_id from sermon_series order by series_id desc limit 1;"`

      for sermon in series.search(".series_links > ul > li")
        sermon_metadata = compile_sermon_metadata(sermon)
        db.execute("insert into sermons (title, passage, sermon_series_id, audio_url, transcript_url) values (?, ?, ?, ?, ?)",
                    sermon_metadata["title"],
                    sermon_metadata["passage"],
                    series_id,
                    "nothing right now",
                    "nothing right now")
      end
    end
  end
end

def create_db_tables(db)
  db.execute <<-SQL
    create table if not exists sermon_series (
      series_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT,
      released_on TEXT,
      graphic_url TEXT
    );
  SQL

  db.execute <<-SQL
    create table if not exists sermons (
      sermon_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      passage TEXT,
      sermon_series_id INTEGER NOT NULL,
      audio_url TEXT,
      transcript_url TEXT
    )
  SQL
end

# TODO: upload transcript to S3 and return url

# def download_transcript(sermon, path)
#   if sermon.search(".transcript a")[0]
#     transcript = $agent.click(sermon.search(".transcript a")[0])
#     transcript.save(path + "/Transcript.pdf")
#   end
# end

# TODO: upload audio to S3 and return url

# def download_audio(sermon, path)
#   if sermon.search(".audio a")[0]
#     audio = $agent.click(sermon.search(".audio a")[0])
#     audio.save(path + "/Audio.mp3")
#   end
# end

# TODO: upload graphic to S3 and return url

# def download_graphic(series, path)
#   graphic = series.search(".series_graphic img")[0]
#   if graphic
#     $agent.get(graphic.attribute("src")).save(path + "/Graphic.jpg")
#   end
# end

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
