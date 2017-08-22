require "test_helper"

class TranscriptTest < Minitest::Test
  def test_pdftohtml_version
    `pdftohtml -v 2>&1` =~ /version 0.57.0/
  end

  def test_to_html
    transcript = Collector::Transcript.new("test/fixtures/transcript.pdf")
    assert_equal File.read("test/fixtures/transcript.html"), transcript.to_html
  end
end
