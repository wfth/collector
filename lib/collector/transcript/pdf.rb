require "nokogiri"

module Collector::Transcript
  class PDF
    def self.load(path)
      new(%x(pdftohtml -i -stdout -xml #{path}))
    end

    def initialize(xml)
      @xml = xml
    end

    def document
      @document ||= Document.new(Nokogiri::XML(@xml))
    end

    def to_html
      builder = Nokogiri::HTML::Builder.new do |doc|
        doc.html do |html|
          html.body do |body|
            build_html(body)
          end
        end
      end
      builder.doc.to_xhtml(indent:2)
    end

    def to_xml
      @xml
    end

    private

    def build_html(body)
      document.pages.each do |page|
        body.h1 page.title if page.title
        page.subtitles.each {|e| body.h2 e }
        page.content_elements.each do |element|
          body.p element.text
        end
      end
    end
  end
end
