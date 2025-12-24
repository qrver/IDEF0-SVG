require_relative 'line'

module IDEF0
  class ExternalLine < Line
    def anchor_precedence(side)
      []
    end

    # Default implementation: create separate lines for each target (old behavior)
    # Subclasses can override this to create branching lines
    def self.make_lines_grouped(source, boxes)
      boxes.each do |box|
        make_line(source, box) { |line| yield(line) }
      end
    end
  end
end
