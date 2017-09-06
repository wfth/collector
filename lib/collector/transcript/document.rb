module Collector::Transcript
  class EitherColumn
    def self.==(other)
      :column_left == other || :column_right == other
    end
  end

  class Parser
    attr_reader :content, :state
    private :state

    def initialize(document, page_nodes)
      @document = document
      @page_nodes = page_nodes
      @content = []
      @states = []
      @accumulator = []
    end

    def append(text)
      @accumulator << text
    end

    def capture(type)
      unless @accumulator.empty?
        @content << [type, @accumulator.map(&:text).join.strip]
        @accumulator = []
      end
    end

    def transition(state, capture=false)
      capture(@state) if capture
      @state = state
      @states << state
    end

    def unknown
      transition :unknown, true
    end

    def parse!
      transition :start
      pages = @page_nodes.to_enum
      loop do
        page = pages.next
        texts = page.css("text").to_enum
        loop do
          text = texts.next
          case state
          when :start
            case text_info(text)
            when [:whitespace]
            when [:numeric]
              # ignore page number
            when [:text, :bold, :column_left], [:text, :bold]
              transition :title
              append text
            else
              unknown
            end
          when :title
            case text_info(text)
            when [:whitespace]
              transition :subtitle, true
            when [:text, :bold, :column_right], [:text, :bold]
              append text
            else
              unknown
            end
          when :subtitle
            case text_info(text)
            when [:whitespace]
              ptext = texts.peek
              if @document.center?(text_position(ptext))
                transition :subtitle, true
              else
                transition :body, true
              end
            when [:text, :normal, :document_center]
              append text
            else
              unknown
            end
          when :body
            case text_info(text)
            when [:text, :bold, EitherColumn, :center]
              transition :heading
              append text
            when [:text, :normal, EitherColumn, :indented]
              capture :paragraph
              append text
            when [:text, :normal, EitherColumn]
              append text
            else
              unknown
            end
          when :heading
            case text_info(text)
            when [:text, :bold, EitherColumn, :center]
              append text
            when [:text, :normal]
              transition :body, true
              append text
            else
              unknown
            end
          when :unknown
            raise <<-MESSAGE

            Processing failed: #{@states.inspect}
            #{text_info(text)} #{text_position(text)} #{text.text.inspect}
            Accumulator: #{@accumulator.inspect}
            Content: #{@content.map(&:first).inspect}
            MESSAGE
          else
            states << (state = :unknown)
          end
        end
      end
    end

    def text_info(text)
      info = []

      case text.text
      when /^\s+$/
        info << :whitespace
      when /^\s*\d+\s*$/
        info << :numeric
      else
        info << :text

        info << case [(text > "b").any?, (text > "i").any?]
        when [true, true] then :bold_italic
        when [true, false] then :bold
        when [false, true] then :italic
        else :normal
        end

        position = text_position(text)
        if @document.center?(position)
          info << :document_center
        elsif @document.column_left?(position)
          info << :column_left
          if @document.column_left_indented?(position)
            info << :indented
          elsif @document.column_left_center?(position)
            info << :center
          end
        elsif @document.column_right?(position)
          info << :column_right
          info << :center if @document.column_right_center?(position)
        end
      end
      p [position, info, text.text]
      info
    end

    def text_position(text)
      width = text["width"].to_i
      left = text["left"].to_i
      right = left + width
      center = left + width/2
      [left, center, right]
    end
  end

  class Document
    def initialize(node)
      @node = node
      @page_nodes = @node.css("page")
      @text_nodes = @node.css("text")
    end

    def column_left?(position)
      left_column[0] <= position[0] && left_column[2] >= position[2]
    end

    def column_right?(position)
      right_column[0] <= position[0] && right_column[2] >= position[2]
    end

    def column_left_indented?(position)
      position[0] == left_column_tab_stop
    end

    def column_left_center?(position)
      (left_column[1] - position[1]).abs <= 4
    end

    def column_right_center?(position)
      (right_column[1] - position[1]).abs <= 4
    end

    def center?(position)
      (center - position[1]).abs <= 4
    end

    def content
      parser = Parser.new(self, @page_nodes)
      parser.parse!
      parser.content
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

    def left_column
      @left_column ||= begin
        left = left_margin
        right = @text_nodes.map {|e| e["left"].to_i + e["width"].to_i }.select {|e| e < center}.max
        center = left + ((right - left)/2)
        [left, center, right]
      end
    end

    def left_column_tab_stop
      @left_column_tab_stop ||= begin
        left_texts = @text_nodes.select {|e| (e["left"].to_i + e["width"].to_i) < center}
        left_texts.map {|e| e["left"].to_i }.uniq.sort[1]
      end
    end

    def right_column
      @right_column ||= begin
        left = @text_nodes.map {|e| e["left"].to_i }.select {|e| e > center}.min
        right = width - right_margin
        center = left + ((right - left)/2)
        [left, center, right]
      end
    end

    def width
      @width ||= @page_nodes.map { |e| e["width"].to_i }.max
    end
  end
end
