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
  for t in texts
    plain_text = plain_text + " " + t.text
  end

  puts plain_text
end

params = parse_params
main(params)
