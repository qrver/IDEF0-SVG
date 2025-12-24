require_relative 'point'
require_relative 'labels'
require_relative 'external_line'

module IDEF0
  class ExternalGuidanceLine < ExternalLine
    attr_reader :targets, :target_anchors

    def self.make_line(source, target)
      source.top_side.each_anchor do |anchor|
        yield(new(source, target, anchor.name)) if target.top_side.expects?(anchor.name)
      end
    end

    def self.make_lines_grouped(source, boxes)
      # Group boxes by the concept names they expect on top_side
      concepts_to_boxes = {}

      source.top_side.each_anchor do |anchor|
        targets = boxes.select { |box| box.top_side.expects?(anchor.name) }
        concepts_to_boxes[anchor.name] = targets unless targets.empty?
      end

      # Create one line per concept, potentially with multiple targets (branching)
      concepts_to_boxes.each do |name, targets|
        yield(new(source, targets, name))
      end
    end

    def initialize(source, targets, name)
      # Support both single target (for compatibility) and multiple targets (Array or ArraySet)
      @targets = (targets.is_a?(Array) || targets.is_a?(IDEF0::ArraySet)) ? targets : [targets]
      super(source, @targets.first, name)
      @targets.each { |target| clear(target.top_side, 20) }
    end

    def attach
      @target_anchors = @targets.map { |target| target.top_side.attach(self) }
      @target_anchor = @target_anchors.first  # for compatibility
      self
    end

    def bounds(bounds)
      @targets.each do |target|
        add_clearance_from(target.top_side, y1 - bounds.y1 + 40)
      end
    end

    def avoid(lines, bounds_extension)
      claim = 0
      while lines.any? { |other| label.overlapping?(other.label) } do
        claim += 20
        @targets.each { |target| add_clearance_from(target.top_side, -20) }
      end
      bounds_extension.north = claim
    end

    def extend_bounds(extension)
      @targets.each { |target| add_clearance_from(target.top_side, extension.north) }
    end

    def x1
      if @target_anchors.size == 1
        @target_anchors.first.x
      else
        # Center point between all target anchors
        (@target_anchors.map(&:x).min + @target_anchors.map(&:x).max) / 2
      end
    end

    def y1
      y2 - clearance_from(@targets.first.top_side)
    end

    def x2
      x1
    end

    def left_edge
      [label.left_edge, @target_anchors.map(&:x).min].compact.min
    end

    def right_edge
      [label.right_edge, @target_anchors.map(&:x).max].compact.max
    end

    def label
      CentredLabel.new(@name, Point.new(x1, y1+20-5))
    end

    def clearance_group(side)
      return 2 if @targets.any? { |target| side == target.top_side }
      super
    end

    def to_svg
      if @target_anchors.size == 1
        # Single target - draw simple line
        anchor = @target_anchors.first
        <<-XML
#{svg_line(x1, y1+20, anchor.x, anchor.y)}
#{svg_down_arrow(anchor.x, anchor.y)}
#{label.to_svg}
XML
      else
        # Multiple targets - draw branching line
        branch_y = y1 + 20
        svg_parts = []

        # Main vertical line from top
        svg_parts << svg_line(x1, y1+20, x1, branch_y)

        # Horizontal branch line
        min_x = @target_anchors.map(&:x).min
        max_x = @target_anchors.map(&:x).max
        svg_parts << svg_line(min_x, branch_y, max_x, branch_y)

        # Vertical lines to each target with arrows
        @target_anchors.each do |anchor|
          svg_parts << svg_line(anchor.x, branch_y, anchor.x, anchor.y)
          svg_parts << svg_down_arrow(anchor.x, anchor.y)
        end

        svg_parts << label.to_svg
        svg_parts.join("\n")
      end
    end
  end
end
