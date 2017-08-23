require "test_helper"

class TranscriptPageTest < Minitest::Test
  def setup
    @doc = Nokogiri::HTML.parse(File.read("test/fixtures/transcript.xml"))
  end

  def xtest_content_elements_page_1
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
    I have specifically begun addressing the men in this series of messages entitled, “The Affections of a Godly Man”.  The truths, however, from Romans, chapter 1, certainly apply to every believer.  They are, I believe, truths that every woman can pray her husband becomes; truths that every daughter can look for in a future husband; truths that every son can grow up to be like.
    When Paul wrote to the Christians living in Rome, Italy, beginning in chapter 1, and verse 8, we are given, among many wonderful truths, a personal look at the apostle Paul.  This is the man who shocks us with his candor, as he writes in his first letter to the Corinthians, in chapter 4, verse 16,
    Therefore I exhort you, be imitators of me.
    He could say that, not because he was perfect, but because he was progressing in his walk and was a little further down the path than the others.
    In the verses that we are about to look at, in Romans, chapter 1, we will discover, as Barnhouse observed, what made the apostle Paul “tick”.  What did he think about?  What did he long for?  What did he feel passionate about doing?  What drove his affections in life?
    We will also discover a model for every man.  This model is from a man who was not behind a pulpit, nor behind a university lectern, nor in front of a public audience making some carefully developed speech, but was a man on his knees.
    E. M. Bounds was born in 1835.  At one time, this lawyer served as a chaplain in the Civil War.  Afterwards, he served as a pastor.  He spent the last eighteen years of his life in prayer and writing.  His writings would be ignored until long after his death, yet his words are as needed today as at any other time in modern history.  He wrote the following potent words,
    LINES

    lines.each_with_index do |l, i|
      assert_equal l.strip, page.content_elements[i].text, "Page 1, line #{i} is not as expected"
    end
  end

  def xtest_content_elements_page_2
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
    Paul is saying, in this one phrase, “My entire life, my being, my working, my serving is devoted to the honor and glory of God.”
    You might say, “Well, Paul is supposed to say that.  I mean, he’s an apostle and apostles are supposed to live like that.”
    It would be wonderful to agree with you, because then we would all be off the hook.  However, there is that troubling little verse that I referenced at the beginning of our study, where Paul said, “Imitate me!  Live like me!  I’m showing you how to walk, so walk like me.”
    Godly living is not a sport, it is work.  It is not something you do only if you feel like it, or if you have some spare time for it, or if you are naturally good at it.  Paul told Timothy, in I Timothy, chapter 4, verse 7b,
    .  .  .  discipline  yourself  for  the  purpose  of godliness
    Paul said to discipline or train yourself.  The word “train” is the word, “gumnazo,” from which we get our word, “gymnasium”.  In other words, “Timothy, go into the gymnasium of the Spirit and work out in the Word and, if you’re not breaking out into spiritual sweat, you’re probably not working hard enough.”
    Later, in that same paragraph, Paul tells Timothy that this godliness is something for which we labor and strive.  The word “labor” is the Greek word from which we get our word “agonize”.
    So, Paul speaks of gaining godliness with words like “agonizing” and “training,” just as an athlete would train and push himself in order to run a race.  In fact, Paul uses that very analogy in I Corinthians, chapter 9.
    I have heard people say, “I don’t read the Bible because it’s hard to understand,” or, “I don’t pray like I ought to because that has just never come easy for me,” or, “I’d like to memorize scripture but it takes forever.”
    They have never understood that successful Christian living requires spiritual sweat.
    J. Sidlow Baxter pastored in the early 1900’s.  At one point, in his own walk and growth in Christ, he took a good look into his heart.  He found that there was a part of him that wanted to pray and a part of him that did not.  The part that did was his will and intellect; the part that did not was his emotions.  He wrote of how he struggled and fought in order to gain personal victory.
    LINES

    lines.each_with_index do |l, i|
      assert_equal l.strip, page.content_elements[i].text, "Page 2, line #{i} is not as expected"
    end
  end

  def test_content_elements_page_3
    page = Collector::Transcript::Page.new(@doc.css("page")[2])

    lines = <<~LINES.lines()
    As never before, my  will and I stood face to face.  I asked my will the straight question, “Will, are you ready for an hour of prayer?”
    Will answered, “Here I am, and I’m quite ready, if you are.”
    So  Will  and  I  linked  arms  and  turned  to go  for  our  time  of  prayer.    At  once  all  the emotions  began  pulling  the  other  way  and protesting, “We are not coming.”
    I  saw  Will  stagger  just  a  bit,  so  I  asked, “Can you stick it out, Will?”
    Will replied, “Yes, if you can.”
    So Will went, and we got down to prayer, dragging  those  wriggling,  rambunctious emotions  with  us.    It  was  a  struggle  all  the way  through.    At  one  point,  when  Will  and  I were  in  the  middle  of  earnest  intercession,  I suddenly  found  one  of  those  traitorous emotions had snared my imagination and had run  off  to  the  golf  course;  and  it  was  all  I could  do  to  drag  the  wicked  rascal  back.    A bit  later  I  found  another  of  the  emotions  had sneaked away with some off-guarded thoughts.    At  the  end  of  that  hour,  if  you  had asked  me,  “Have  you  had  a  good  time?”    I would  have  had  to  reply,  “No,  it  has  been  a wearying  wrestle  with  contrary  emotions  and a truant imagination from beginning to end.”
    Well, that battle continued for some time. And  if  you  asked  me,  “Have  you  had  a  good time  in  your  daily  praying?”    I  would  have had to confess, “No, at times it has seemed as though  the  heavens  were  brass,  and  God  too distant  to  hear,  and  the  Lord  Jesus  strangely aloof, and prayer accomplishing nothing.”
    Yet,  something  was  happening.    For  one thing,  Will  and  I  were  slowly  teaching Emotion that we were completely independent of  them.    Also,  one  morning,  just  when  Will and I were going for another time of prayer, I overheard one of the emotions  whisper to the other,  “Come  on,  you  guys,  it  is  not  useful wasting  any  more  time  resisting;  they’ll  go< just the same.”
    That  morning,  for  the  first  time,  even though  the  emotions  were  still  suddenly uncooperative, they were at least quiet, which allowed  Will  and  me  to  get  on  with  prayer without distraction.   Then, another couple of weeks  later,  what  do  you  think  happened? During  one  of  our  prayer  times,  when  Will and  I  were  no  more  thinking  of  the  emotions than of the man in the moon, one of the most vigorous of the emotions unexpectedly sprang up  and  shouted,  “Hallelujah!”  at  which  all the other emotions said, “Amen!”
    And  for  the  first  time  the  whole  of  my being  –  intellect,  will  and  emotions  –  was untied in one coordinated prayer operation. ii
    A godly life, ladies and gentlemen, is never a coincidence!
    A godly man’s affection for godly living compels him to persist in a life-long devotion; to intensely battle the flesh; to struggle and agonize for purity in and through every fabric of his being; to resist the philosophy of the world system, until body, soul, and spirit cooperate at times, in true and holy living for Christ and His church.  In other words, a holy man does not just happen!
    Would you struggle to kneel and beg God to make you a holy man?  If you would, be ready at some point, to talk with strange words like these, “I am deeply devoted to God with my whole heart.”
    Observe Paul’s godly praying
    2. The second thing to observe about Paul, in verse 9, is his godly praying.
    I say the words “godly praying” purposefully, because it is possible to pray in an ungodly way.
    James, chapter 4, tells us how, as he rebukes believers for asking God for things with selfish motives in order to have more ease, more comfort, and more things.  He writes, in verse 3,
    You ask and do not receive, because you ask with wrong motives, so that you may spend it on your pleasures.
    Notice how Paul prayed, in the last part of verse 9,
    For  God  .  .  .  is  my  witness  as  to  how unceasingly I make mention of [myself]
    “And, oh, do I have problems.  Just recently I learned that there is a plot to kill me.”
    And there was.
    “I already had enough trouble with the law.  In fact, I still have bruises from my last beating.  There isn’t a day that goes by that I don’t unceasingly pray about myself and I’d like you, in Rome, to do the same.”
    Oh, I misread one little word of verse 9, didn’t I?
    LINES

    lines.each_with_index do |l, i|
      assert_equal l.strip, page.content_elements[i].text, "Page 3, line #{i} is not as expected"
    end
  end
end
