require 'mork/grid'
require 'mork/coord'
require 'deep_merge/rails_compat'

module Mork
  # @private
  class GridOMR < Grid
    OVERLAY_STROKE_WIDTH_MM = 0.5

    def initialize(options=nil)
      super options
    end

    def set_page_size(width, height)
      @px = width.to_f
      @py = height.to_f
      self
    end

    def overlay_stroke_width_px
      [(pixels_per_unit * OVERLAY_STROKE_WIDTH_MM).round, 1].max
    end

    def barcode_areas(bits)
      [].tap do |areas|
        bits.each_with_index do |b, i|
          areas << barcode_bit_area(i+1) if b
        end
      end
    end

    # ===========================================
    # = Returning Coord sets for area locations =
    # ===========================================
    def choice_cell_areas
      @choice_cell_areas ||= begin
        max_questions.times.map do |q|
          max_choices_per_question.times.map do |c|
            coord cell_x(q,c), cell_y(q), cell_width, cell_height
          end
        end
      end
    end

    def choice_cell_area(q, c)
      choice_cell_areas[q][c]
    end

    def crossbox_choice_cell_area(q, c)
      crossbox_inset_area cell_x(q, c), cell_y(q), cell_width, cell_height
    end

    def calibration_cell_areas
      rows.times.map do |q|
        coord cal_cell_x, cell_y(q), cell_width, cell_height
      end
    end

    def crossbox_calibration_cell_areas
      rows.times.map do |q|
        crossbox_inset_area cal_cell_x, cell_y(q), cell_width, cell_height
      end
    end

    def barcode_bit_area(bit)
      coord barcode_bit_x(bit), barcode_y, barcode_width, barcode_height
    end

    def identity_cell_areas
      return [] unless identity?

      @identity_cell_areas ||= identity_digits.times.map do |row|
        10.times.map do |digit|
          coord identity_cell_x(digit), identity_cell_y(row), identity_cell_width, identity_cell_height
        end
      end
    end

    def rm_crop_area(corner)
      coord rx(corner), ry(corner), reg_crop, reg_crop, ppu_x, ppu_y
    end

    def paper_white_area() barcode_bit_area(-1) end
    def ink_black_area()   barcode_bit_area( 0) end

    private

    def cx()    @px / reg_frame_width  end
    def cy()    @py / reg_frame_height end
    def pixels_per_unit() (ppu_x + ppu_y) / 2.0 end
    def ppu_x() @px / page_width       end
    def ppu_y() @py / page_height      end

    def coord(x, y, w, h, cX=cx, cY=cy)
      Coord.new w, h: h, x: x, y: y, cx: cX, cy: cY
    end

    def crossbox_inset_area(x, y, width, height)
      inset = crossbox_inset
      if inset.negative? || inset * 2 >= [width, height].min
        fail ArgumentError, 'crossbox_inset must be non-negative and less than half the cell dimensions'
      end

      coord x + inset, y + inset, width - inset * 2, height - inset * 2
    end

    # iterationless x registration
    def rx(corner)
      case corner
      when :tl; reg_off
      when :tr; page_width - reg_crop - reg_off
      when :br; page_width - reg_crop - reg_off
      when :bl; reg_off
      end
    end

    def ry(corner)
      case corner
      when :tl; reg_off
      when :tr; reg_off
      when :br; page_height - reg_crop - reg_off
      when :bl; page_height - reg_crop - reg_off
      end
    end
  end
end
