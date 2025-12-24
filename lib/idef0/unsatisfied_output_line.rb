module IDEF0
  class UnsatisfiedOutputLine < ExternalOutputLine
    def self.make_line(target, source)
      source.right_side.each_unattached_anchor do |anchor|
        target.right_side.expects(anchor.name)
        yield(new(source, target, anchor.name))
      end
    end

    def self.make_lines_grouped(target, boxes)
      # Group boxes by the unattached anchor names on their right_side
      concepts_to_boxes = {}

      boxes.each do |box|
        box.right_side.each_unattached_anchor do |anchor|
          concepts_to_boxes[anchor.name] ||= []
          concepts_to_boxes[anchor.name] << box
        end
      end

      # Create one line per concept, potentially with multiple sources (branching)
      concepts_to_boxes.each do |name, sources|
        target.right_side.expects(name)
        yield(new(sources, target, name))
      end
    end

    alias_method :svg_line, :svg_dashed_line
  end
end
