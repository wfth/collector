require "test_helper"

class TranscriptParserPageTest < Minitest::Test
  def setup
    @doc = Nokogiri::HTML.parse <<-HTML
<page number="1" position="absolute" top="0" left="0" height="1188" width="918">
	<fontspec id="0" size="13" family="Times" color="#000000"/>
	<fontspec id="1" size="43" family="Times" color="#000000"/>
	<fontspec id="2" size="34" family="Times" color="#000000"/>
	<fontspec id="3" size="14" family="Times" color="#000000"/>
	<fontspec id="4" size="16" family="Times" color="#000000"/>
	<fontspec id="5" size="22" family="Times" color="#000000"/>
	<fontspec id="6" size="14" family="Times" color="#000000"/>
<text top="57" left="76" width="4" height="14" font="0"> </text>
<text top="1104" left="76" width="4" height="14" font="0"> </text>
<text top="1104" left="835" width="11" height="14" font="0">1 </text>
<text top="194" left="842" width="11" height="41" font="1"><b> </b></text>
<text top="236" left="459" width="11" height="41" font="1"><b> </b></text>
<text top="287" left="303" width="25" height="41" font="1"><b>S</b></text>
<text top="293" left="328" width="190" height="32" font="2"><b>truggling to </b></text>
<text top="287" left="518" width="35" height="41" font="1"><b>K</b></text>
<text top="293" left="553" width="71" height="32" font="2"><b>neel </b></text>
<text top="331" left="459" width="4" height="15" font="3"> </text>
<text top="351" left="313" width="296" height="16" font="4">The Affections of a Godly Man – Part II </text>
<text top="371" left="459" width="4" height="15" font="3"> </text>
<text top="391" left="404" width="115" height="16" font="4">Romans 1:9-10 </text>
<text top="411" left="459" width="4" height="15" font="3"> </text>
<text top="432" left="188" width="137" height="22" font="5"><b>Introduction </b></text>
<text top="464" left="103" width="337" height="15" font="3">I have been preaching a series of sermons to men.  </text>
<text top="482" left="76" width="348" height="15" font="3">The response from many men has been encouraging </text>
<text top="501" left="76" width="87" height="15" font="3">and moving. </text>
<text top="526" left="103" width="314" height="15" font="3">One man jokingly said to me, “You know, I’ve </text>
<text top="545" left="76" width="333" height="15" font="3">noticed, over the years, that you’re a lot harder on </text>
<text top="564" left="76" width="199" height="15" font="3">men that you are on women.” </text>
<text top="589" left="103" width="280" height="15" font="3">He is probably right.  I do believe that the </text>
<text top="608" left="76" width="358" height="15" font="3">fundamental responsibility for leading the church, the </text>
<text top="627" left="76" width="343" height="15" font="3">home, the marriage, and the family is the shepherd, </text>
<text top="646" left="76" width="295" height="15" font="3">and every man is, in some way, a shepherd.  </text>
<text top="665" left="76" width="338" height="15" font="3">However, I do not like the idea that I am harder on </text>
<text top="684" left="76" width="121" height="15" font="3">men than women. </text>
<text top="709" left="103" width="304" height="15" font="3">One man sent some rather funny things about </text>
<text top="728" left="76" width="340" height="15" font="3">women and marriage to me.  At first I thought they </text>
<text top="747" left="76" width="352" height="15" font="3">would be too blunt to repeat, but after that comment, </text>
<text top="766" left="76" width="318" height="15" font="3">I thought I would take a chance and balance the </text>
<text top="785" left="76" width="330" height="15" font="3">scales between the men and the women a little by </text>
<text top="804" left="76" width="153" height="15" font="3">reading a few of them. </text>
<text top="829" left="103" width="308" height="15" font="3">One fellow said, “I married Miss Right.  I just </text>
<text top="848" left="76" width="276" height="15" font="3">didn’t know her first name was Always.” </text>
<text top="873" left="103" width="310" height="15" font="3">“The last argument I had with my wife was all </text>
<text top="892" left="76" width="237" height="15" font="3">my fault,” one man said to another. </text>
<text top="917" left="103" width="142" height="15" font="3">“Oh, why was that?” </text>
<text top="942" left="103" width="318" height="15" font="3">“Well, she asked me what was on the TV, and I </text>
<text top="961" left="76" width="93" height="15" font="3">said, ‘Dust.’” </text>
<text top="986" left="103" width="223" height="15" font="3">I think that is enough, don’t you? </text>
<text top="1011" left="103" width="318" height="15" font="3">I have specifically begun addressing the men in </text>
<text top="1030" left="76" width="352" height="15" font="3">this series of messages entitled, “The Affections of a </text>
<text top="1049" left="76" width="334" height="15" font="3">Godly Man”.  The truths, however, from Romans, </text>
<text top="1068" left="76" width="333" height="15" font="3">chapter 1, certainly apply to every believer.  They </text>
<text top="430" left="486" width="344" height="15" font="3">are, I believe, truths that every woman can pray her </text>
<text top="449" left="486" width="359" height="15" font="3">husband becomes; truths that every daughter can look </text>
<text top="468" left="486" width="324" height="15" font="3">for in a future husband; truths that every son can </text>
<text top="487" left="486" width="128" height="15" font="3">grow up to be like. </text>
<text top="512" left="513" width="290" height="15" font="3">When Paul wrote to the Christians living in </text>
<text top="530" left="486" width="349" height="15" font="3">Rome, Italy, beginning in chapter 1, and verse 8, we </text>
<text top="550" left="486" width="348" height="15" font="3">are given, among many wonderful truths, a personal </text>
<text top="569" left="486" width="353" height="15" font="3">look at the apostle Paul.  This is the man who shocks </text>
<text top="587" left="486" width="337" height="15" font="3">us with his candor, as he writes in his first letter to </text>
<text top="606" left="486" width="259" height="15" font="3">the Corinthians, in chapter 4, verse 16, </text>
<text top="632" left="513" width="294" height="15" font="6"><i><b>Therefore I exhort you, be imitators of me. </b></i></text>
<text top="656" left="513" width="308" height="15" font="3">He could say that, not because he was perfect, </text>
<text top="676" left="486" width="358" height="15" font="3">but because he was progressing in his walk and was a </text>
<text top="694" left="486" width="286" height="15" font="3">little further down the path than the others. </text>
<text top="719" left="513" width="292" height="15" font="3">In the verses that we are about to look at, in </text>
<text top="738" left="486" width="341" height="15" font="3">Romans, chapter 1, we will discover, as Barnhouse </text>
<text top="757" left="486" width="344" height="15" font="3">observed, what made the apostle Paul “tick”.  What </text>
<text top="776" left="486" width="353" height="15" font="3">did he think about?  What did he long for?  What did </text>
<text top="795" left="486" width="320" height="15" font="3">he feel passionate about doing?  What drove his </text>
<text top="814" left="486" width="119" height="15" font="3">affections in life? </text>
<text top="839" left="513" width="309" height="15" font="3">We will also discover a model for every man.  </text>
<text top="858" left="486" width="322" height="15" font="3">This model is from a man who was not behind a </text>
<text top="877" left="486" width="353" height="15" font="3">pulpit, nor behind a university lectern, nor in front of </text>
<text top="896" left="486" width="346" height="15" font="3">a public audience making some carefully developed </text>
<text top="915" left="486" width="242" height="15" font="3">speech, but was a man on his knees. </text>
<text top="940" left="513" width="308" height="15" font="3">E. M. Bounds was born in 1835.  At one time, </text>
<text top="959" left="486" width="333" height="15" font="3">this lawyer served as a chaplain in the Civil War.  </text>
<text top="978" left="486" width="345" height="15" font="3">Afterwards, he served as a pastor.  He spent the last </text>
<text top="997" left="486" width="344" height="15" font="3">eighteen years of his life in prayer and writing.  His </text>
<text top="1016" left="486" width="347" height="15" font="3">writings would be ignored until long after his death, </text>
<text top="1035" left="486" width="359" height="15" font="3">yet his words are as needed today as at any other time </text>
<text top="1054" left="486" width="332" height="15" font="3">in modern history.  He wrote the following potent </text>
<text top="1073" left="486" width="48" height="15" font="3">words, </text>
</page>
HTML
    @page = Collector::TranscriptParser::Page.new(@doc.css("page").first)
  end

  def test_page
    assert_equal "Struggling to Kneel", @page.title
    assert_equal ["The Affections of a Godly Man – Part II", "Romans 1:9-10"], @page.subtitles
    assert_equal 30, @page.columns[0].texts.size
    assert_equal 33, @page.columns[1].texts.size
  end

  # def test_column
  #   column = @page.columns[0]
  #   assert_equal column.paragraphs.size
  # end
end
