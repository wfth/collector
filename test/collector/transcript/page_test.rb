require "test_helper"

class TranscriptPageTest < Minitest::Test
  include TranscriptTestHelpers

  def setup
    @document = Collector::Transcript::Document.new(transcript_xml)
    @page1 = @document.pages[0]
    @page2 = @document.pages[1]
  end

  def test_title
    assert_equal "Struggling to Kneel", @page1.title
    assert_equal nil, @page2.title
  end

  def test_subtitles
    assert_equal ["The Affections of a Godly Man – Part II", "Romans 1:9-10"], @page1.subtitles
    assert_equal [], @page2.subtitles
  end

  def test_columns
    assert_equal 31, @page1.left_column.texts.size
    assert_equal 33, @page1.right_column.texts.size
  end

  def test_width
    assert_equal 918, @page1.width
    assert_equal 918, @page2.width
  end

  def test_left
    assert_equal 0, @page1.left
    assert_equal 0, @page2.left
  end

  def test_left_margin
    assert_equal 76, @page1.left_margin
    assert_equal 76, @page2.left_margin
  end

  def test_right
    assert_equal 918, @page1.right
    assert_equal 918, @page2.right
  end

  def test_right_margin
    assert_equal 65, @page1.right_margin
    assert_equal 65, @page2.right_margin
  end

  def test_center
    assert_equal 459, @page1.center
    assert_equal 459, @page2.center
  end

  def test_left_column_left
    assert_equal 76, @page1.left_column.left
    assert_equal 76, @page2.left_column.left
  end

  def test_left_column_right
    assert_equal 440, @page1.left_column.right
    assert_equal 440, @page2.left_column.right
  end

  def test_left_column_center
    assert_equal 258, @page1.left_column.center
    assert_equal 258, @page2.left_column.center
  end

  def test_right_column_left
    assert_equal 486, @page1.right_column.left
    assert_equal 486, @page2.right_column.left
  end

  def test_right_column_right
    assert_equal 853, @page1.right_column.right
    assert_equal 853, @page2.right_column.right
  end

  def test_right_column_center
    assert_equal 669, @page1.right_column.center
    assert_equal 669, @page2.right_column.center
  end
end
