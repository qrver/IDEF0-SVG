module IDEF0
  class UnsatisfiedInputLine < ExternalInputLine
    def self.make_line(source, target)
      target.left_side.each_unattached_anchor do |anchor|
        source.left_side.expects(anchor.name)
        yield(new(source, target, anchor.name))
      end
    end

    def self.make_lines_grouped(source, boxes)
      # Group boxes by the unattached anchor names on their left_side
      concepts_to_boxes = {}

      boxes.each do |box|
        box.left_side.each_unattached_anchor do |anchor|
          concepts_to_boxes[anchor.name] ||= []
          concepts_to_boxes[anchor.name] << box
        end
      end

      # Create one line per concept, potentially with multiple targets (branching)
      concepts_to_boxes.each do |name, targets|
        source.left_side.expects(name)
        yield(new(source, targets, name))
      end
    end

    alias_method :svg_line, :svg_dashed_line
  end
end
