require "nokogiri"

module Collector
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

    def build_html(body)

    end

    # def paragraphs
    #   unless @paragraphs
    #     @paragraphs = []
    #     content_elements = @pages.map {|e| e.content_elements}.flatten
    #     content_elements.each do |e|
    #       case e.type
    #       when :paragraph_start
    #         @paragraphs <<
    #       unless @paragraphs.last && @paragraphs.last.
    #         element = ContentElement.new
    #         element.accept_text(text)
    #         elements << element
    #       end
    #     end
    #   end
    #   @paragraphs
    # end

    class Page
      attr_reader :node, :title, :subtitles, :left_column, :right_column, :texts

      def initialize(node)
        @node = node
        @texts = node.css("text").map {|e| Text.new(e, self)}
        initialize!
      end

      def left
        node["left"].to_i
      end

      def right
        width
      end

      def center
        width/2
      end

      def width
        node["width"].to_i
      end

      def initialize!
        enum = texts.each
        consume_page_number(enum)
        consume_title(enum)
        consume_subtitles(enum)
        consume_columns(enum)
      end

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
        consume_matching(enum) {|t| t.whitespace?}
      end

      def consume_page_number(enum)
        consume_whitespace(enum)
        consume_matching(enum) {|t| t =~ /\d+/}
      end

      def consume_title(enum)
        consume_whitespace(enum)
        @title = consume_matching(enum) {|t| t.bold?}.strip
      end

      def consume_subtitle(enum)
        consume_whitespace(enum)
        consume_matching(enum) {|t| t.page_centered? && !t.whitespace?}.strip
      end

      def consume_subtitles(enum)
        @subtitles = [consume_subtitle(enum)]
        consume_whitespace(enum)
        if peek(enum).page_centered?
          @subtitles << consume_subtitle(enum)
        end
      end

      def consume_columns(enum)
        consume_whitespace(enum)

        @left_column = begin
          left = texts.map {|e| e.left}.min
          right = texts.select {|e| (e.left + e.width) < center }.map {|e| e.left + e.width}.max
          Column.new(self, left, right)
        end

        @right_column = begin
          left = texts.select {|e| e.left > center}.map {|e| e.left}.min
          right = texts.map {|e| e.left + e.width}.max
          Column.new(self, left, right)
        end

        @columns = [@left_column, @right_column]

        loop do
          text = enum.next
          @columns.each {|c| c.accept_text text}
        end
      end

      def peek(enum)
        enum.peek rescue Text.new(Nokogiri::XML::Node.new("nil", @node))
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
        left + (right-left)/2
      end

      def left_indent
        @left_indent ||= @texts.map {|e| e.left}.uniq.sort[1].to_i
      end

      # Answers text if accepted, nil if not
      def accept_text(text)
        if text.left >= left && text.right <= right
          text.column = self
          @texts << text
        end
      end

      def content_elements
        @content_elements ||= @texts.inject([]) do |elements, text|
          unless elements.last && elements.last.accept_text(text)
            element = ContentElement.new
            element.accept_text(text)
            elements << element
          end
          elements
        end
      end
    end

    class ContentElement
      attr_reader :texts

      def initialize
        @texts = []
      end

      # Answers text if accepted, nil if not
      def accept_text(text)
        if accept_text?(text)
          @first_type ||= text.type
          @first_top ||= text.top
          @texts << text
        end
      end

      def text
        texts.map {|t| t.text}.join.strip
      end

      def accept_text?(text)
        p [[text.left, text.center, text.right],[text.column.left, text.column.left_indent, text.column.center, text.column.right], @first_type, text.type, text.text]

        @texts.empty? ||
        text.type == :footnote_reference ||
        text.type == :whitespace ||
        text.top == @first_top ||
          case [@first_type, text.type]
          when [:block_quote, :block_quote] then true
          when [:paragraph_start, :paragraph] then true
          when [:paragraph, :paragraph] then true
          when [:section_heading, :section_heading] then true
          else
            false
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

      def whitespace?
        node.text =~ /^\s+$/
      end

      def bold?
        (node > "b").any?
      end

      def italic?
        (node > "i").any?
      end

      def left
        node["left"].to_i
      end

      def right
        left + width
      end

      def height
        node["height"].to_i
      end

      def width
        node["width"].to_i
      end

      def top
        node["top"].to_i
      end

      def nil?
        node.name == "nil"
      end

      def left_justified?
        left == column.left
      end

      def footnote_reference?
        height < 10 && italic?
      end

      def indented?
        left == column.left_indent
      end

      # The text is centered in the column if the center of the text overlaps
      # the center of the column.
      def column_centered?
        (column.center - center).abs <= 4
      end

      # The text is centered on the page if the center of the text overlaps the
      # center of the page.
      def page_centered?
        (page.center - center).abs <= 4
      end

      def center
        left + width/2
      end

      def text
        node.text
      end

      def column_position
        if left_justified?
          :left
        elsif indented?
          :indented
        elsif column_centered?
          :center
        else
          :unknown
        end
      end

      def font_weight
        case [bold?, italic?]
        when [true, true]
          :bold_italic
        when [true, false]
          :bold
        when [false, true]
          :italic
        else
          :normal
        end
      end

      def type
        if footnote_reference?
          :footnote_reference
        elsif whitespace?
          :whitespace
        else
          case [column_position, font_weight]
          when [:center, :bold]
            :section_heading
          when [:indented, :normal]
            :paragraph_start
          when [:indented, :bold_italic]
            :block_quote
          when [:indented, :italic]
            :block_quote
          when [:left, :normal]
            :paragraph
          else
            :unknown
          end
        end
      end

      def =~(r)
        text =~ r
      end

      def inspect
        "<#{type}: '#{text}'>"
      end
    end

  end
end
