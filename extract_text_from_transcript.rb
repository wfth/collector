$LOAD_PATH.unshift(".")

require "nokogiri"

def parse_params
  if ARGV.length == 1
    ARGV[0]
  else
    STDERR.puts("Usage: ruby extract_text_from_transcript.rb <PDF-file>")
    exit(false)
  end
end

def main(pdf_doc)
  transcript_xml = %x( pdftohtml -stdout -xml #{pdf_doc} )
  transcript = Nokogiri::XML(transcript_xml)
  texts = transcript.css("text")
  plain_text = ""

  last_broke = false
  for t in texts
    if t.attribute("width").value.to_i < 15 || t.text.length < 2
      next
    end

    new_text = t.text

    if t.attribute("height").value.to_i > 15
      new_text = "<h4>" + new_text + "</h4>"
      plain_text = plain_text + new_text
      last_broke = true
      next
    end

    if t.attribute("width").value.to_i < 240 && last_broke != true
      plain_text = plain_text + " " + new_text + "</p>\n\n"
      last_broke = true
    elsif last_broke
      plain_text = plain_text + "<p>" + new_text
      last_broke = false
    else
      plain_text = plain_text + " " + new_text
    end
  end

  puts plain_text + "</p>"
end

params = parse_params
main(params)
