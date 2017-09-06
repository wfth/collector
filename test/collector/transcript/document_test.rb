require "test_helper"

class TranscriptDocumentTest < Minitest::Test
  include TranscriptTestHelpers

  def setup
    @subject = Collector::Transcript::Document.new(transcript_xml)
  end

  def test_left_column
    assert_equal [76, 258, 440], @subject.left_column
  end

  def test_right_column
    assert_equal [486, 669, 853], @subject.right_column
  end

  def test_left_column_tab_stop
    assert_equal 103, @subject.left_column_tab_stop
  end

  def test_left_margin
    assert_equal 76, @subject.left_margin
  end

  def test_right_margin
    assert_equal 65, @subject.right_margin
  end

  def test_width
    assert_equal 918, @subject.width
  end

  def test_center
    assert_equal 459, @subject.center
  end

  def test_center?
    assert @subject.center?([345, 456, 567])
    assert !@subject.center?([345, 450, 555])
  end

  def test_column_left?
    assert @subject.column_left?([103, 220, 337])
    assert !@subject.column_left?([328, 423, 518])
  end

  def test_title
    assert_equal [
      [:title, "Struggling to Kneel"],
      [:subtitle, "The Affections of a Godly Man – Part II"],
      [:subtitle, "Romans 1:9-10"],
      [:heading, "Introduction"]
    ], @subject.content
  end
end
