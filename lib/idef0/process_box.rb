require_relative 'box'
require_relative 'labels'

# TODO: Probably could just call this a ChildBox?
module IDEF0
  class ProcessBox < Box
    attr_accessor :sequence

    def precedence
      [-right_side.anchor_count, [left_side, top_side, bottom_side].map(&:anchor_count).reduce(&:+)]
    end

    def width
      [Label.length(display_name)+40, [top_side.anchor_count, bottom_side.anchor_count].max*20+20].max
    end

    def height
      [60, [left_side.anchor_count, right_side.anchor_count].max*20+20].max
    end

    def after?(other)
      sequence > other.sequence
    end

    def before?(other)
      sequence < other.sequence
    end

    def extract_number
      @name =~ /^\[([^\]]+)\]/ ? $1 : nil
    end

    def display_name
      @name.gsub(/^\[([^\]]+)\]\s*/, '')
    end

    def to_svg
      number = extract_number
      name_text = display_name

      svg = <<-XML
<rect x='#{x1}' y='#{y1}' width='#{width}' height='#{height}' fill='none' stroke='black' />
<text text-anchor='middle' x='#{x1 + (width / 2)}' y='#{y1 + (height / 2)}'>#{name_text}</text>
XML

      if number
        svg += <<-XML
<text text-anchor='end' x='#{x2 - 5}' y='#{y2 - 5}' font-size='10'>#{number}</text>
XML
      end

      svg
    end
  end
end
