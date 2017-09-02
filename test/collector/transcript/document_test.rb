require "test_helper"

class TranscriptDocumentTest < Minitest::Test
  include TranscriptTestHelpers

  def setup
    @subject = Collector::Transcript::Document.new(transcript_xml)
  end

  def test_left
    assert_equal 76, @subject.left
  end

  def test_right
    assert_equal 853, @subject.right
  end

  def test_width
    assert_equal 918, @subject.width
  end

  def test_center
    assert_equal 459, @subject.center
  end
end
