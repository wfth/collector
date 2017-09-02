module Collector::Transcript
  class Content
    attr_reader :texts

    def initialize(type)
      @texts = []
    end

    def initialize(texts=[])
      @texts = texts
      initialize!(texts.first) unless texts.empty?
    end

    def initialize!(text)
      @first_type ||= text.type
      @first_top ||= text.top
    end

    # Answers text if accepted, nil if not
    def accept_text(text)
      if accept_text?(text)
        initialize!(text) if @texts.empty?
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

    def continuation?(preceding)
      texts.all? {|e| preceding.accept_text?(e)}
    end
  end
end
