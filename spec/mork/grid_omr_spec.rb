require 'spec_helper'

module Mork
  describe GridOMR do
    before(:each) do
      @grom = GridOMR.new 'spec/samples/grid_omr_layout.yml'
      @grom.set_page_size 1601, 2281
    end

    describe '#choice_cell_area' do
      it 'returns the coordinates of the first choice cell' do
        puts
        expect(@grom.choice_cell_area(0,0)).to have_coords(63, 436, 51, 41)
      end

      it 'returns the coordinates of the last choice cell' do
        expect(@grom.choice_cell_area(119,4)).to have_coords(1411, 2108, 51, 41)
      end
    end

    describe '#crossbox_choice_cell_area' do
      it 'insets the evaluation area by the configured layout margin' do
        grom = GridOMR.new({ crossbox_inset: 0.5 }).set_page_size(1601, 2281)
        cell = grom.choice_cell_area(0, 0)
        interior = grom.crossbox_choice_cell_area(0, 0)

        expect(interior.x).to be > cell.x
        expect(interior.y).to be > cell.y
        expect(interior.w).to be < cell.w
        expect(interior.h).to be < cell.h
      end

      it 'rejects an inset that eliminates the cell interior' do
        grom = GridOMR.new({ crossbox_inset: 2.5 }).set_page_size(1601, 2281)

        expect { grom.crossbox_choice_cell_area(0, 0) }
          .to raise_error(ArgumentError, /crossbox_inset/)
      end
    end

    describe '#barcode_bit_area' do
      it 'returns the coordinates of the first barcode bit area' do
        expect(@grom.barcode_bit_area(0)).to have_coords(126, 2260, 25, 21)
      end

      it 'returns the coordinates of the last barcode bit area' do
        expect(@grom.barcode_bit_area(39)).to have_coords(1441, 2260, 25, 21)
      end
    end

    describe '#identity_cell_areas' do
      let(:identity) do
        {
          digits: 2,
          left: 20,
          top: 30,
          cell_width: 4,
          cell_height: 3,
          x_spacing: 5,
          y_spacing: 6
        }
      end

      it 'returns no areas when identity is not configured' do
        expect(@grom.identity_cell_areas).to eq []
      end

      it 'places ten digit cells in every identity row' do
        grom = GridOMR.new(identity: identity).set_page_size(1900, 2970)

        expect(grom.identity_cell_areas.length).to eq 2
        expect(grom.identity_cell_areas.first.length).to eq 10
        expect(grom.identity_cell_areas[0][0]).to have_coords(180, 306, 40, 32)
        expect(grom.identity_cell_areas[1][9]).to have_coords(630, 370, 40, 32)
      end
    end

    describe '#rm_crop_area' do
      it 'returns a Coord object for the :tl reg_mark corner' do
        c = @grom.rm_crop_area :tl
        expect(c). to have_coords(15, 15, 152, 154)
      end

      it 'returns a Coord object for the :tr reg_mark corner' do
        c = @grom.rm_crop_area :tr
        expect(c).to have_coords(1433, 15, 152, 154)
      end

      it 'returns a Coord object for the :br reg_mark corner' do
        c = @grom.rm_crop_area :br
        expect(c).to have_coords(1433, 2112, 152, 154)
      end

      it 'returns a Coord object for the :bl reg_mark corner' do
        c = @grom.rm_crop_area :bl
        expect(c).to have_coords(15, 2112, 152, 154)
      end
    end

    describe '#max_choices_per_question' do
      it 'returns the maximum number of choice cells per question' do
        expect(@grom.max_choices_per_question).to eq 5
      end
    end

    describe '#overlay_stroke_width_px' do
      it 'keeps the default visual width on the reference scan' do
        grom = GridOMR.new 'spec/samples/jdoe/layout.yml'
        grom.set_page_size 1240, 1754
        expect(grom.overlay_stroke_width_px).to eq 3
      end

      it 'scales with scan resolution' do
        grom = GridOMR.new 'spec/samples/jdoe/layout.yml'
        grom.set_page_size 2480, 3508
        expect(grom.overlay_stroke_width_px).to eq 6
      end
    end

    describe '#paper_white_area' do
      it 'returns the coordinates of the white area used for barcode calibration' do
        expect(@grom.paper_white_area).to have_coords(93, 2260, 25, 21)
      end
    end

    describe '#ink_black_area' do
      it 'returns the coordinates of the barcode calibration bar' do
        expect(@grom.ink_black_area).to have_coords(126, 2260, 25, 21)
      end
    end
  end
end


# it 'fails if an invalid barcode bit is requested' do
#   lambda { @grom.barcode_bit_area(40) }.should raise_error
# end

# describe '#rm_edgy_x' do
#   it 'returns the minimum acceptable number of pixels from the regmark center to the edge of the rm_crop_area' do
#     @grom.rm_edgy_x.should == 24
#   end
#   it 'returns an integer' do
#     @grom.rm_edgy_x.should be_an Integer
#   end
# end

# describe '#rm_edgy_y' do
#   it 'returns the minimum acceptable number of pixels from the regmark center to the edge of the rm_crop_area' do
#     @grom.rm_edgy_y.should == 24
#   end
#   it 'returns an integer' do
#     @grom.rm_edgy_y.should be_an Integer
#   end
# end

# describe '#rm_max_search_area_side' do
#   it 'returns the maximum extent of the regmark search area, 1/4 of the raw image horizontal pixels' do
#     @grom.rm_max_search_area_side.should == 400
#   end
#   it 'returns an integer' do
#     @grom.rm_max_search_area_side.should be_an Integer
#   end
# end
