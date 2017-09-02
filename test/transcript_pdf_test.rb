require "test_helper"

class TranscriptPDFTest < Minitest::Test
  def test_pdftohtml_version
    `pdftohtml -v 2>&1` =~ /version 0.57.0/
  end

  def test_to_html
    pdf = Collector::Transcript::PDF.load("test/fixtures/transcript.pdf")
    assert_equal File.read("test/fixtures/transcript.html"), pdf.to_html
  end
end
