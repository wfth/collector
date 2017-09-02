module Collector::Transcript
  class Text
    attr_reader :page, :container, :node

    def initialize(page, container, node)
      @page = page
      @container = container
      @node = node
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
      left == container.left
    end

    def footnote_reference?
      height < 10 && italic?
    end

    def indented?
      left == container.left_indent
    end

    # The text is centered in the container if the center of the text overlaps
    # the center of the container.
    def centered?
      (container.center - center).abs <= 4
    end

    def center
      left + width/2
    end

    def text
      node.text
    end

    def container_position
      if left_justified?
        :left
      elsif indented?
        :indented
      elsif centered?
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
        case [container_position, font_weight]
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
