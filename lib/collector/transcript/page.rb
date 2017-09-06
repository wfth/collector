module Collector::Transcript
  class Page
    attr_reader :document, :node

    def initialize(document, node)
      @document = document
      @node = node

      @left_column ||= Column.new(self, document.column_settings[0])
      @right_column ||= Column.new(self, document.column_settings[1])
      @columns = [@left_column, @right_column]

      # TODO must iterate the text nodes in the Document, and build a tree
      # current_container = self
      # node.css("text").each do |n|
      #   container = self
      #   container = @left_column if (n["left"].to_i + n["width"].to_i) <= @left_column.right
      #   container = @right_column if n["left"].to_i >= @right_column.left
      #   Text.new(self, container, n)
      # end
      #
      # process_text!
    end

    def append_text(text)
      @texts << text
    end

    def inspect
      "<page##{number}"
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

    def number
      node["number"].to_i
    end

    def width
      node["width"].to_i
    end

    private

    def process_text!
      enum = texts.each
      consume_page_number(enum)
      consume_title(enum)
      consume_subtitles(enum)
      consume_columns(enum)
    end

    def content_elements
      @content_elements ||= begin
        left_elements = left_column.content_elements.map {|e| ContentElement.new(e.texts)}
        right_elements = right_column.content_elements.map {|e| ContentElement.new(e.texts)}
        last_element = left_elements.last
        next_element = right_elements.first
        if next_element.continuation?(last_element)
          next_element.texts.each {|e| last_element.accept_text(e)}
          right_elements = right_elements[1..-1]
        end
        [left_elements, right_elements].flatten
      end
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
      title = consume_matching(enum) {|t| t.bold?}.strip
      @title = title unless title == ""
    end

    def consume_subtitle(enum)
      consume_whitespace(enum)
      consume_matching(enum) {|t| t.page_centered? && !t.whitespace?}.strip
    end

    def consume_subtitles(enum)
      @subtitles = []
      if node["number"].to_i == 1
        @subtitles << consume_subtitle(enum)
        consume_whitespace(enum)
        if peek(enum).page_centered?
          @subtitles << consume_subtitle(enum)
        end
      end
    end

    def consume_columns(enum)
      consume_whitespace(enum)
      loop do
        text = enum.next
        @columns.each {|c| c.accept_text text}
      end
    end

    def peek(enum)
      enum.peek rescue Text.new(self, nil, Nokogiri::XML::Node.new("nil", @node))
    end
  end
end
