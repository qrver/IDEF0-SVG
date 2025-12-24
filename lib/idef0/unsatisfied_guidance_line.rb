module IDEF0
  class UnsatisfiedGuidanceLine < ExternalGuidanceLine
    def self.make_line(source, target)
      target.top_side.each_unattached_anchor do |anchor|
        source.top_side.expects(anchor.name)
        yield(new(source, target, anchor.name))
      end
    end

    def self.make_lines_grouped(source, boxes)
      # Group boxes by the unattached anchor names on their top_side
      concepts_to_boxes = {}

      boxes.each do |box|
        box.top_side.each_unattached_anchor do |anchor|
          concepts_to_boxes[anchor.name] ||= []
          concepts_to_boxes[anchor.name] << box
        end
      end

      # Create one line per concept, potentially with multiple targets (branching)
      concepts_to_boxes.each do |name, targets|
        source.top_side.expects(name)
        yield(new(source, targets, name))
      end
    end

    alias_method :svg_line, :svg_dashed_line
  end
end
