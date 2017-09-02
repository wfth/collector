module Collector::Transcript
  class Column
    attr_reader :page, :left, :right, :texts

    def initialize(page, settings)
      @page = page
      @left = settings[:left]
      @right = settings[:right]
      @texts = []
    end

    def <<(text)
      @texts << text
    end

    def center
      left + (right-left)/2
    end

    def left_indent
      @left_indent ||= @texts.map {|e| e.left}.uniq.sort[1].to_i
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
end
