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

def integer_of_attr(tag, attr)
  return -1 if tag == nil
  tag.attribute(attr).value.to_i
end

def main(pdf_doc)
  transcript_xml = %x( pdftohtml -stdout -xml #{pdf_doc} )
  transcript = Nokogiri::XML(transcript_xml)
  texts = transcript.css("text")
  plain_text = ""

  last_broke = false
  last_line = nil
  breakable_line_length = 245

  text_enum = texts.to_enum
  loop do
    line = text_enum.next
    new_text = line.text
    next_line = text_enum.peek
    next_text = next_line.text

    if integer_of_attr(line, "width") < 15 || line.text.length < 2
      next
    end

    if integer_of_attr(line, "height") > 15
      new_text = "<h4>" + new_text + "</h4>"
      plain_text = plain_text + new_text
      last_broke = true
      next
    end

    line_indented = integer_of_attr(line, "left") > integer_of_attr(next_line, "left") && integer_of_attr(line, "left") > integer_of_attr(last_line, "left")
    line_short = integer_of_attr(line, "width") < breakable_line_length
    next_line_short = integer_of_attr(next_line, "width") < breakable_line_length
    next_line_has_punctuation = ["!", ".", "?", ",", "-", "'", "\""].include?(next_text.chars.last)
    should_close_p = (line_short || (next_line_short && !next_line_has_punctuation))

    new_text = "<p>" + new_text if last_broke || line_indented
    new_text = new_text + "</p>" if should_close_p
    new_text = " " + new_text if !last_broke

    last_broke = should_close_p

    plain_text = plain_text + new_text
    last_line = line
  end

  puts plain_text + "</p>"
end

params = parse_params
main(params)
