require 'numo/narray'

module Mork
  # @private
  # NPatch handles low-level computations on pixels by leveraging Numo::NArray
  class NPatch
    # NPatch.new(source, width, height) constructs an NPatch object
    # from the `source` linear array of bytes, to be reshaped as a
    # `width` by `height` matrix
    def initialize(source, width, height)
      # Numo::NArray uses row-major order, so we reshape and transpose
      @patch = Numo::SFloat.cast(source).reshape(height, width).transpose
    end

    def average(coord)
      @patch[coord.x_rng, coord.y_rng].mean
    end

    # Mean grayscale value along the two interior diagonals of a response cell.
    def average_cross(coord)
      average_masked(coord, masks_for(coord.w, coord.h).first)
    end

    # Mean grayscale value in the interior, excluding the diagonal cross area.
    def average_off_cross(coord)
      average_masked(coord, masks_for(coord.w, coord.h).last)
    end

    def stddev(coord)
      @patch[coord.x_rng, coord.y_rng].stddev
    end

    def centroid
      xp = @patch.sum(axis: 1).to_a
      yp = @patch.sum(axis: 0).to_a
      return xp.find_index(xp.min), yp.find_index(yp.min), @patch.stddev
    end

    private

    def average_masked(coord, indices)
      values = @patch[coord.x_rng, coord.y_rng].flatten.to_a
      indices.sum { |index| values[index] } / indices.length.to_f
    end

    def masks_for(width, height)
      @masks_for ||= {}
      @masks_for[[width, height]] ||= begin
        x_start = (width * 0.15).ceil
        x_end = (width * 0.85).floor
        y_start = (height * 0.15).ceil
        y_end = (height * 0.85).floor
        x_span = [x_end - x_start - 1, 1].max
        y_span = [y_end - y_start - 1, 1].max

        cross = []
        off_cross = []
        (x_start..x_end).each do |x|
          (y_start..y_end).each do |y|
            normalized_x = (x - x_start).to_f / x_span
            normalized_y = (y - y_start).to_f / y_span
            on_diagonal = (normalized_x - normalized_y).abs <= 0.12 ||
                          (normalized_x + normalized_y - 1).abs <= 0.12
            (on_diagonal ? cross : off_cross) << x * height + y
          end
        end
        [cross, off_cross]
      end
    end
  end
end
