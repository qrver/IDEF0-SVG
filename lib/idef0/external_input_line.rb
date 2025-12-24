require_relative 'point'
require_relative 'labels'
require_relative 'external_line'

module IDEF0
  class ExternalInputLine < ExternalLine
    attr_reader :targets, :target_anchors

    def self.make_line(source, target)
      source.left_side.each_anchor do |anchor|
        yield(new(source, target, anchor.name)) if target.left_side.expects?(anchor.name)
      end
    end

    def self.make_lines_grouped(source, boxes)
      # Group boxes by the concept names they expect on left_side
      concepts_to_boxes = {}

      source.left_side.each_anchor do |anchor|
        targets = boxes.select { |box| box.left_side.expects?(anchor.name) }
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
      @targets.each { |target| clear(target.left_side, 20) }
    end

    def attach
      @target_anchors = @targets.map { |target| target.left_side.attach(self) }
      @target_anchor = @target_anchors.first  # for compatibility
      self
    end

    def x1
      x2 - clearance_from(@targets.first.left_side)
    end

    def y1
      if @target_anchors.size == 1
        @target_anchors.first.y
      else
        # Center point between all target anchors
        (@target_anchors.map(&:y).min + @target_anchors.map(&:y).max) / 2
      end
    end

    def y2
      y1
    end

    def bounds(bounds)
      @targets.each do |target|
        add_clearance_from(target.left_side, x1 - bounds.x1 + 40)
      end
    end

    def avoid(lines, bounds_extension)
      bounds_extension.west = minimum_length
    end

    def extend_bounds(extension)
      @targets.each { |target| add_clearance_from(target.left_side, extension.west) }
    end

    def top_edge
      [@target_anchors.map(&:y).min, y1].compact.min
    end

    def bottom_edge
      [@target_anchors.map(&:y).max, y1].compact.max
    end

    def label
      LeftAlignedLabel.new(@name, Point.new(x1+5, y1-5))
    end

    def clearance_group(side)
      return 2 if @targets.any? { |target| side == target.left_side }
      super
    end

    def to_svg
      if @target_anchors.size == 1
        # Single target - draw simple line
        anchor = @target_anchors.first
        <<-XML
#{svg_line(x1, y1, anchor.x, anchor.y)}
#{svg_right_arrow(anchor.x, anchor.y)}
#{label.to_svg}
XML
      else
        # Multiple targets - draw branching line
        branch_x = x1 + 20
        svg_parts = []

        # Main horizontal line from left
        svg_parts << svg_line(x1, y1, branch_x, y1)

        # Vertical branch line
        min_y = @target_anchors.map(&:y).min
        max_y = @target_anchors.map(&:y).max
        svg_parts << svg_line(branch_x, min_y, branch_x, max_y)

        # Horizontal lines to each target with arrows
        @target_anchors.each do |anchor|
          svg_parts << svg_line(branch_x, anchor.y, anchor.x, anchor.y)
          svg_parts << svg_right_arrow(anchor.x, anchor.y)
        end

        svg_parts << label.to_svg
        svg_parts.join("\n")
      end
    end
  end
end
