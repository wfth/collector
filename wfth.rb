require 'pp'
require 'rubygems'
require 'mechanize'
require 'json'

# TODO
# - Report progress better
# - Create better sermon metadata (null passages, not full passages)

$agent = Mechanize.new

def main
  puts "Loading all messages...\n"
  messages_page = $agent.get("http://www.wisdomonline.org/media/messages")
  scripture_links = messages_page.search("div#scripture li a")
  
  for scripture in scripture_links
    puts "Loading #{scripture_links.index(scripture) + 1} scripture..."
    scripture_page = $agent.click(scripture)

    for series in scripture_page.search(".series_list > li")
      series_base_path = "/tmp/WFTH/#{scripture.text}/#{series.search(".title").text}"
      FileUtils.mkdir_p series_base_path
      
      puts "Compiling series metadata..."
      compile_series_metadata(series, series_base_path)

      puts "Downloading series graphic..."
      download_graphic(series, series_base_path)
      
      for sermon in series.search(".series_links > ul > li")
        extract_data(scripture, series, sermon, series_base_path)
      end
    end
  end
end

def extract_data(scripture, series, sermon, base_path)
  puts "Downloading transcript..."
  download_transcript(sermon, base_path + "/#{sermon.search(".sermon_title").text}")

  puts "Compiling sermon metadata..."
  compile_sermon_metadata(sermon, base_path + "/#{sermon.search(".sermon_title").text}")

  puts "Downloading sermon audio..."
  download_audio(sermon, base_path + "/#{sermon.search(".sermon_title").text}")

  puts "Finished!"
end

def download_transcript(sermon, path)
  if sermon.search(".transcript a")[0]
    transcript = $agent.click(sermon.search(".transcript a")[0])
    transcript.save(path + "/Transcript.pdf")
  end
end

def download_audio(sermon, path)
  if sermon.search(".audio a")[0]
    audio = $agent.click(sermon.search(".audio a")[0])
    audio.save(path + "/Audio.mp3")
  end
end

def download_graphic(series, path)
  graphic = series.search(".series_graphic img")[0]
  if graphic
    $agent.get(graphic.attribute("src")).save(path + "/Graphic.jpg")
  end
end

def compile_series_metadata(series, path)
  metadata = {
    "title" => series.search(".title").text,
    "date" => series.search(".date").text,
    "description" => series.search(".description p").text
  }

  if series.search(".link-buy-series")[0]
    metadata["buy_link"] = series.search(".link-buy-series")[0].attributes["href"].text
  end

  File.open(path + "/metadata.json", "w") do |f|
    f.write(metadata.to_json)
  end
end

def compile_sermon_metadata(sermon, path)
  metadata = {
    "passage" => sermon.search(".sermon_title").text[/\w+ \d{1,3}:\d{1,3}/] # doesn't work with Genesis 1:1-29 or other "through" passages
  }

  if sermon.search(".buy_single a")[0]
    metadata["buy_link"] = sermon.search(".buy_single a").attribute("href").text
  end

  File.open(path + "/metadata.json", "w") do |f|
    f.write(metadata.to_json)
  end
end

def number_ending(num)
  case num % 10
  when 1
    "st"
  when 2
    "nd"
  when 3
    "rd"
  else
    "th"
  end
end

main()
