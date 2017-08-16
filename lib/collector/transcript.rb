require "nokogiri"

module Collector
  class TranscriptParser

    module Parser
      private

      def consume_matching(enum, content="", &block)
        text = enum.peek rescue nil
        while text && (block.nil? || block.call(text))
          content << text.text
          enum.next
          text = enum.peek rescue nil
        end
        content
      end

      def consume_whitespace(enum)
        consume_matching(enum) {|t| t.blank?}
      end

      def peek(enum)
        enum.peek rescue Text.new(Nokogiri::XML::Node.new("nil", @node))
      end
    end

    class Page
      include Parser

      attr_reader :node, :title, :subtitles, :columns

      def initialize(node)
        @node = node
        parse!
      end

      def center
        width/2
      end

      def width
        node["width"].to_i
      end

      private

      def parse!
        texts = node.css("text").map {|e| Text.new(e, self)}
        enum = texts.each
        consume_page_number(enum)
        @title = consume_title(enum)
        @subtitles = consume_subtitles(enum)
        @columns = consume_columns(enum)
      end

      def consume_page_number(enum)
        consume_whitespace(enum)
        consume_matching(enum) {|t| t =~ /\d+/}
      end

      def consume_title(enum)
        consume_whitespace(enum)
        consume_matching(enum) {|t| t.bold?}.strip
      end

      def consume_subtitle(enum)
        consume_whitespace(enum)
        consume_matching(enum) {|t| t.page_centered? && !t.blank?}.strip
      end

      def consume_subtitles(enum)
        subtitles = [consume_subtitle(enum)]
        consume_whitespace(enum)
        if peek(enum).page_centered?
          subtitles << consume_subtitle(enum)
        end
        subtitles
      end

      def consume_columns(enum)
        consume_whitespace(enum)
        columns = [Column.new(self, 0, center), Column.new(self, center, width)]
        loop do
          text = enum.next
          columns.each {|c| c.accept_text text}
        end
        columns
      end
    end

    class Column
      attr_reader :page, :left, :right, :texts

      def initialize(page, left, right)
        @page = page
        @left = left
        @right = right
        @texts = []
      end

      def center
        left + right/2
      end

      def accept_text(text)
        if text.left >= left && text.right <= right
          @texts << text
          text.column = self
        end
      end
    end

    class Text
      attr_reader :node, :page
      attr_accessor :column

      def initialize(node, page)
        @node = node
        @page = page
      end

      def blank?
        node.text =~ /^\s+$/
      end

      def bold?
        (node > "b").any?
      end

      def left
        node["left"].to_i
      end

      def right
        left + width
      end

      def width
        node["width"].to_i
      end

      def nil?
        node.name == "nil"
      end

      # The text is centered in the column if the center of the text overlaps
      # the center of the column.
      def column_centered?
        (column.center - center).abs < 5
      end

      # The text is centered on the page if the center of the text overlaps the
      # center of the page.
      def page_centered?
        (page.center - center).abs < 5
      end

      def center
        left + width/2
      end

      def italic?
        (node > "i").any?
      end

      def text
        node.text
      end

      def column_position
        if column_centered?
          :center
        else
          :unknown
        end
      end

      def font_weight
        bold? ? :bold : :normal
      end

      def type
        case [column_position, font_weight]
        when [:center, :bold]
          :section_heading
        when [:indented, :normal]
          :paragraph_start
        when [:left, :normal]
          :paragraph
        end
      end

      def =~(r)
        text =~ r
      end

      def inspect
        "<text: '#{text}'>"
      end
    end

    class Content
      attr_reader :type

      def initialize
        @texts = []
      end

      def compatible_text?(text)
        type.nil? || type == text.type
      end

      def <<(text)
        if compatible_text?(text)
          @type ||= text.type
          @texts << text
        else
          raise "Incompatible text #{text.type.inspect}, expected #{type.inspect}"
        end
      end
    end

    def initialize(converter)
      @c = converter
    end

    def parse(xml)
      content = Content.new # content may span two pages
      pages = xml.css("page").map {|e| Page.new(e)}
      pages.each do |page|
        page.title
        page.subtitles
        page.columns.each do |column|
          enum = column.texts.each
          consume_whitespace(enum)
          consume_page_number(enum)
          loop do
            # consume_whitespace(enum)
            text = enum.next
            unless content.compatible_text?(text)
              @c.send(content.type, content)
              content = Content.new
            end
            content << text
          end
        end
      end
    end

    private

    def build_html(builder)
      paragraph = Paragraph.new
      node.css("page").each_with_index do |page, page_number|
        texts = node.css("text").map {|n| Text.new(n)}
        enum = texts.each
        consume_whitespace(enum)
        consume_page_number(enum)
        if page_number == 0
          build_title(enum, builder)
          build_subtitles(enum, builder)
        end
        loop do
          consume_whitespace(enum)
          text = enum.next
          case text.type
          when :section_heading
          when :paragraph_start
          end
        end
      end
    end
  end

  class TranscriptHTML
    def start_page(page)

    end

    def end_page(page)

    end
  end

  class Transcript
    attr_reader :path
    attr_writer :xml

    def initialize(path)
      @path = path
    end

    def to_xml
      @xml ||= %x( pdftohtml -i -stdout -xml #{path} )
    end

    def node
      @node ||= Nokogiri::XML(to_xml)
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

    def to_html1
      html = ""
      texts = transcript_xml.css("text")

      last_broke = false
      last_line = nil
      breakable_line_length = 245

      text_enum = texts.to_enum
      loop do
        line = text_enum.next
        new_text = line.text
        next_line = text_enum.peek
        next_text = next_line.text

        if integer_of_attr(line, "width") < 15 || line.text.length < 2
          next
        end

        if integer_of_attr(line, "height") > 15
          new_text = "<h4>" + new_text + "</h4>"
          html = html + new_text
          last_broke = true
          next
        end

        line_indented = integer_of_attr(line, "left") > integer_of_attr(next_line, "left") && integer_of_attr(line, "left") > integer_of_attr(last_line, "left")
        line_short = integer_of_attr(line, "width") < breakable_line_length
        next_line_short = integer_of_attr(next_line, "width") < breakable_line_length
        next_line_has_punctuation = ["!", ".", "?", ",", "-", "'", "\""].include?(next_text.chars.last)
        should_close_p = (line_short || (next_line_short && !next_line_has_punctuation))

        new_text = "<p>" + new_text if last_broke || line_indented
        new_text = new_text + "</p>" if should_close_p
        new_text = " " + new_text if !last_broke

        last_broke = should_close_p

        html = html + new_text
        last_line = line
      end

      html + "</p>"
    end

    def integer_of_attr(tag, attr)
      return -1 if tag == nil
      tag.attribute(attr).value.to_i
    end
  end
end
