require_relative 'point'
require_relative 'labels'
require_relative 'external_line'

module IDEF0
  class ExternalOutputLine < ExternalLine
    attr_reader :sources, :source_anchors

    def self.make_line(target, source)
      source.right_side.each_anchor do |anchor|
        yield(new(source, target, anchor.name)) if target.right_side.expects?(anchor.name)
      end
    end

    def self.make_lines_grouped(target, boxes)
      # Group boxes by the concept names they produce on right_side
      concepts_to_boxes = {}

      boxes.each do |box|
        box.right_side.each_anchor do |anchor|
          if target.right_side.expects?(anchor.name)
            concepts_to_boxes[anchor.name] ||= []
            concepts_to_boxes[anchor.name] << box
          end
        end
      end

      # Create one line per concept, potentially with multiple sources (branching)
      concepts_to_boxes.each do |name, sources|
        yield(new(sources, target, name))
      end
    end

    def initialize(sources, target, name)
      # Support both single source (for compatibility) and multiple sources (Array or ArraySet)
      @sources = (sources.is_a?(Array) || sources.is_a?(IDEF0::ArraySet)) ? sources : [sources]
      super(@sources.first, target, name)
      @sources.each { |source| clear(source.right_side, 20) }
    end

    def attach
      @source_anchors = @sources.map { |source| source.right_side.attach(self) }
      @source_anchor = @source_anchors.first  # for compatibility
      self
    end

    def x1
      if @source_anchors.size == 1
        @source_anchors.first.x
      else
        # Rightmost source anchor
        @source_anchors.map(&:x).max
      end
    end

    def y1
      if @source_anchors.size == 1
        @source_anchors.first.y
      else
        # Center point between all source anchors
        (@source_anchors.map(&:y).min + @source_anchors.map(&:y).max) / 2
      end
    end

    def x2
      x1 + clearance_from(@sources.first.right_side)
    end

    def y2
      y1
    end

    def bounds(bounds)
      @sources.each do |source|
        add_clearance_from(source.right_side, bounds.x2 - x2 + 40)
      end
    end

    def avoid(lines, bounds_extension)
      claim = 0
      while lines.any? { |other| label.overlapping?(other.label) } do
        claim += 20
        @sources.each { |source| add_clearance_from(source.right_side, 20) }
      end
      @sources.each { |source| add_clearance_from(source.right_side, -claim) }
      bounds_extension.east = [minimum_length, claim].max
    end

    def extend_bounds(extension)
      @sources.each { |source| add_clearance_from(source.right_side, extension.east) }
    end

    def top_edge
      [@source_anchors.map(&:y).min, y1].compact.min
    end

    def bottom_edge
      [@source_anchors.map(&:y).max, y1].compact.max
    end

    def label
      RightAlignedLabel.new(@name, Point.new(x2-8, y2-8))
    end

    def clearance_group(side)
      return 2 if @sources.any? { |source| side == source.right_side }
      super
    end

    def to_svg
      if @source_anchors.size == 1
        # Single source - draw simple line
        anchor = @source_anchors.first
        <<-XML
#{svg_line(anchor.x, anchor.y, x2, y2)}
#{svg_right_arrow(x2, y2)}
#{label.to_svg}
XML
      else
        # Multiple sources - draw branching line (collecting from multiple boxes)
        branch_x = x2 - 20
        svg_parts = []

        # Main horizontal line to right
        svg_parts << svg_line(branch_x, y1, x2, y2)
        svg_parts << svg_right_arrow(x2, y2)

        # Vertical branch line
        min_y = @source_anchors.map(&:y).min
        max_y = @source_anchors.map(&:y).max
        svg_parts << svg_line(branch_x, min_y, branch_x, max_y)

        # Horizontal lines from each source
        @source_anchors.each do |anchor|
          svg_parts << svg_line(anchor.x, anchor.y, branch_x, anchor.y)
        end

        svg_parts << label.to_svg
        svg_parts.join("\n")
      end
    end
  end
end
