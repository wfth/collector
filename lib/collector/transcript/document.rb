module Collector::Transcript
  class Document
    attr_reader :node

    def initialize(node)
      @node = node
      @page_nodes = @node.css("page")
      @text_nodes = @node.css("text")
    end

    def column_settings
      @column_settings ||= [
        {
          left: left_margin,
          right: @text_nodes.map {|e| e["left"].to_i + e["width"].to_i }.select {|e| e < center}.max
        },
        {
          left: @text_nodes.map {|e| e["left"].to_i }.select {|e| e > center}.min,
          right: width - right_margin
        }
      ]
    end

    def pages
      @pages ||= @page_nodes.map { |e| Page.new(self, e) }
    end

    def center
      @center ||= width/2
    end

    def left_margin
      @left ||= @text_nodes.map { |e| e["left"].to_i }.min
    end

    def right_margin
      @right ||= width - @text_nodes.map { |e| e["left"].to_i + e["width"].to_i }.max
    end

    def width
      @width ||= @page_nodes.map { |e| e["width"].to_i }.max
    end
  end
end
