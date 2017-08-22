require "test_helper"

class TranscriptPageTest < Minitest::Test
  def setup
    @doc = Nokogiri::HTML.parse(File.read("test/fixtures/transcript.xml"))
  end

  def test_content_elements_page_1
    page = Collector::Transcript::Page.new(@doc.css("page")[0])

    lines = <<~LINES.lines()
    Introduction
    I have been preaching a series of sermons to men.  The response from many men has been encouraging and moving.
    One man jokingly said to me, “You know, I’ve noticed, over the years, that you’re a lot harder on men that you are on women.”
    He is probably right.  I do believe that the fundamental responsibility for leading the church, the home, the marriage, and the family is the shepherd, and every man is, in some way, a shepherd.  However, I do not like the idea that I am harder on men than women.
    One man sent some rather funny things about women and marriage to me.  At first I thought they would be too blunt to repeat, but after that comment, I thought I would take a chance and balance the scales between the men and the women a little by reading a few of them.
    One fellow said, “I married Miss Right.  I just didn’t know her first name was Always.”
    “The last argument I had with my wife was all my fault,” one man said to another.
    “Oh, why was that?”
    “Well, she asked me what was on the TV, and I said, ‘Dust.’”
    I think that is enough, don’t you?
    I have specifically begun addressing the men in this series of messages entitled, “The Affections of a Godly Man”.  The truths, however, from Romans, chapter 1, certainly apply to every believer.  They
    LINES

    lines.each_with_index do |l, i|
      assert_equal l.strip, page.left_column.content_elements[i].text, "Page 1, line #{i} is not as expected"
    end

    lines = <<~LINES.lines()
    are, I believe, truths that every woman can pray her husband becomes; truths that every daughter can look for in a future husband; truths that every son can grow up to be like.
    When Paul wrote to the Christians living in Rome, Italy, beginning in chapter 1, and verse 8, we are given, among many wonderful truths, a personal look at the apostle Paul.  This is the man who shocks us with his candor, as he writes in his first letter to the Corinthians, in chapter 4, verse 16,
    Therefore I exhort you, be imitators of me.
    He could say that, not because he was perfect, but because he was progressing in his walk and was a little further down the path than the others.
    In the verses that we are about to look at, in Romans, chapter 1, we will discover, as Barnhouse observed, what made the apostle Paul “tick”.  What did he think about?  What did he long for?  What did he feel passionate about doing?  What drove his affections in life?
    We will also discover a model for every man.  This model is from a man who was not behind a pulpit, nor behind a university lectern, nor in front of a public audience making some carefully developed speech, but was a man on his knees.
    E. M. Bounds was born in 1835.  At one time, this lawyer served as a chaplain in the Civil War.  Afterwards, he served as a pastor.  He spent the last eighteen years of his life in prayer and writing.  His writings would be ignored until long after his death, yet his words are as needed today as at any other time in modern history.  He wrote the following potent words,
    LINES

    lines.each_with_index do |l, i|
      assert_equal l.strip, page.right_column.content_elements[i].text, "Page 1, line #{i} is not as expected"
    end
  end

  def test_content_elements_page_2
    page = Collector::Transcript::Page.new(@doc.css("page")[1])

    lines = <<~LINES.lines()
    We  are  constantly  on  a  stretch,  if  not  on  a strain, to devise new methods, new plans, new organizations  to  advance  the  church  .  .  .  but while  the  church  is  looking  for  better methods, God is looking for better men.  What the  church  needs  today  is  not  more machinery,  not  new  organizations  or  more and  novel  methods,  but  men  whom  the  Holy Spirit  can  use  –  men  mighty  in  prayer.    The Holy  Spirit  does  not  flow  through  methods, but  through  men.  He  does  not  come  on machinery,  but  on  men.    He  does  not  anoint plans, but men – men of prayer.i
    The Prayer Closet of the Apostle Paul
    I invite you to join me in the private prayer room of the apostle Paul and discover what the affections of a godly man truly are.  Let us begin by reading verses 8 through 10 of Romans, chapter 1.
    First,  I  thank  my  God  through  Jesus  Christ for  you  all,  because  your  faith  is  being proclaimed throughout the whole world.  For God,  whom  I  serve  in  my  spirit  in  the preaching  of  the  gospel  of  His  Son,  is  my witness  as  to  how  unceasingly  I  make mention  of  you,  always  in  my  prayers making request, if perhaps now at last by the will of God I may succeed in coming to you.
    You cannot help but observe, as Paul leafs through his prayer list, several things about him.
    Observe Paul’s godly piety
    1. First, observe Paul’s godly piety.
    “Piety” is another word for, “devotion, or sacred allegiance, or reverence”.
    Paul wrote, in verse 9,
    For God, whom I serve in my spirit . . .
    I believe that Paul’s use of the words “in my spirit,” is intended to convey the intensity of his devotion to God.  He is, in effect, saying, “I am serving God with my whole being,” or, as the New International Version translates it, “with my whole heart”!
    This is an expression that is deeply emotional.
    Add to that the fact that Paul’s word translated “serve,” is the Greek word, “latreuo,” which is translated, “worship”.  It combines the ideas of devotion and action.  Worship is living for God, and serving God is worshipping God.
    LINES

    lines.each_with_index do |l, i|
      assert_equal l.strip, page.left_column.content_elements[i].text, "Page 2, line #{i} is not as expected"
    end
  end
end
