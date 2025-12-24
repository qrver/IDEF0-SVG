module IDEF0
  class Label
    def self.length(text)
      text.length * 6
    end

    def initialize(text, point)
      @text = text
      @point = point
    end

    def length
      self.class.length(@text)
    end

    def top_edge
      @point.y - 20
    end

    def bottom_edge
      @point.y
    end

    def right_edge
      left_edge + length
    end

    def overlapping?(other)
      left_edge < other.right_edge &&
      right_edge > other.left_edge &&
      top_edge < other.bottom_edge &&
      bottom_edge > other.top_edge
    end

    def to_svg
      padding = 4
      rect_x = left_edge - padding
      rect_y = top_edge - padding
      rect_width = length + padding * 2
      rect_height = 20 + padding * 2

      <<-SVG
<rect x='#{rect_x}' y='#{rect_y}' width='#{rect_width}' height='#{rect_height}' fill='white' stroke='none' />
<text text-anchor='#{text_anchor}' x='#{@point.x}' y='#{@point.y}'>#{@text}</text>
SVG
    end
  end

  class LeftAlignedLabel < Label
    def left_edge
      @point.x
    end

    def text_anchor
      "start"
    end
  end

  class RightAlignedLabel < Label
    def left_edge
      @point.x - length
    end

    def text_anchor
      "end"
    end
  end

  class CentredLabel < Label
    def left_edge
      @point.x - length / 2
    end

    def text_anchor
      "middle"
    end
  end
end
