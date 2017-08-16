require "test_helper"

class TranscriptTest < Minitest::Test
  def test_to_html
    transcript = Collector::Transcript.new(nil)
    transcript.xml = <<-XML
    <!DOCTYPE pdf2xml SYSTEM "pdf2xml.dtd">

    <pdf2xml producer="poppler" version="0.57.0">
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
    XML

    html = <<-HTML
<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">
<html xmlns=\"http://www.w3.org/1999/xhtml\">
  <body>
    <h1>Struggling to Kneel</h1>
    <h2>The Affections of a Godly Man &#x2013; Part II</h2>
    <h2>Romans 1:9-10</h2>
  </body>
</html>
HTML
    assert_equal html, transcript.to_html
  end
end
