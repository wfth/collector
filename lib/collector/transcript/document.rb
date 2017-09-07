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

    def transition(state, texts=nil, text=nil, info=nil)
      @state = state
      @states << state
      if texts && text && info
        __send__ state, texts, text, info
      end
    end

    def unknown!(text)
      raise <<-MESSAGE
      \nProcessing failed: #{@states.inspect}
      #{text_info(text)} #{text_position(text)} #{text.text.inspect}
      Accumulator: #{@accumulator.map {|e| e.text}.join.inspect}
      Content: #{@content.map(&:first).inspect}
      MESSAGE
    end

    def parse!
      transition :start
      pages = @page_nodes.to_enum
      loop do
        transition :new_page unless @state == :start
        page = pages.next
        texts = page.css("text").to_enum
        loop do
          text = texts.next
          info = text_info(text)
          # p [state, text_position(text), info, text.text]
          __send__ state, texts, text, info
        end
      end
    end

    def start(texts, text, info)
      case info
      when [:whitespace]
      when [:numeric]
      when [:text, :bold, :column_left]
        transition :title, texts, text, info
      else
        unknown! text
      end
    end

    def new_page(texts, text, info)
      case info
      when [:whitespace]
      when [:numeric]
      else
        transition :body, texts, text, info
      end
    end

    def body(texts, text, info)
      case info
      when [:whitespace]
      when [:text, :bold, EitherColumn, :center]
        transition :heading, texts, text, info
      when [:text, :bold, EitherColumn, :left_aligned]
        capture :paragraph
        append text
        capture :subheading
      when [:text, :normal, EitherColumn, :indented]
        capture :paragraph
        append text
      when [:text, :normal, EitherColumn, :left_aligned]
        append text
      when [:text, :italic, EitherColumn, :indented]
        capture :paragraph
        transition :blockquote, texts, text, info
      when [:text, :bold_italic, EitherColumn, :indented]
        capture :paragraph
        transition :scripture, texts, text, info
      else
        unknown! text
      end
    end

    def title(texts, text, info)
      case info
      when [:whitespace]
        capture :title
        transition :subtitle
      when [:text, :bold, EitherColumn], [:text, :bold]
        append text
      else
        unknown! text
      end
    end

    def subtitle(texts, text, info)
      case info
      when [:whitespace]
        capture :subtitle
        ptext = texts.peek
        unless @document.center?(text_position(ptext))
          transition :body
        end
      when [:text, :normal, :document_center]
        append text
      else
        unknown! text
      end
    end

    def heading(texts, text, info)
      case info
      when [:text, :bold, EitherColumn, :center]
        append text
      when [:text, :normal, EitherColumn, :indented]
        capture :heading
        transition :body, texts, text, info
      else
        unknown! text
      end
    end

    def scripture(texts, text, info)
      case info
      when [:text, :bold_italic, EitherColumn, :indented]
        append text
      when [:text, :normal, EitherColumn, :indented]
        capture :scripture
        transition :body, texts, text, info
      else
        unknown! text
      end
    end

    def blockquote(texts, text, info)
      case info
      when [:text, :italic, EitherColumn, :indented]
        append text
      when [:text, :italic, EitherColumn]
        ptext = texts.peek
        if text_info(ptext) === [:whitespace]
          capture :blockquote
          append text
          capture :reference
          transition :body
        else
          unknown! text
        end
      else
        unknown! text
      end
    end

    def method_missing(method, *args)
      unknown! args[1]
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

        info << case [text.search("b").any?, text.search("i").any?]
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
          if @document.column_left_margin_aligned?(position)
            info << :left_aligned
          elsif @document.column_left_indented?(position)
            info << :indented
          elsif @document.column_left_center?(position)
            info << :center
          end
        elsif @document.column_right?(position)
          info << :column_right
          if @document.column_right_margin_aligned?(position)
            info << :left_aligned
          elsif @document.column_right_indented?(position)
            info << :indented
          elsif @document.column_right_center?(position)
            info << :center
          end
        end
      end

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

    def column_left_indented?(position)
      position[0] == left_column_tab_stop
    end

    def column_left_center?(position)
      (left_column[1] - position[1]).abs <= 4
    end

    def column_left_margin_aligned?(position)
      left_column[0] == position[0]
    end

    def column_right?(position)
      right_column[0] <= position[0] && right_column[2] >= position[2]
    end

    def column_right_indented?(position)
      position[0] == right_column_tab_stop
    end

    def column_right_center?(position)
      (right_column[1] - position[1]).abs <= 4
    end

    def column_right_margin_aligned?(position)
      right_column[0] == position[0]
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

    def right_column_tab_stop
      @right_column_tab_stop ||= begin
        right_texts = @text_nodes.select {|e| e["left"].to_i > center}
        right_texts.map {|e| e["left"].to_i }.uniq.sort[1]
      end
    end

    def width
      @width ||= @page_nodes.map { |e| e["width"].to_i }.max
    end
  end
end
