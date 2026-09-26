require 'spec_helper'

module Mork
  describe Mimage do
    let(:qna) { [5] * 100 }

    describe '#marked with crossboxes' do
      it 'accepts crosses, ignores blank cells, and voids filled cells' do
        mim = Mimage.allocate
        grom = double(
          crossbox?: true,
          choice_threshold: 0.75,
          crossbox_calibration_cell_areas: [:cal]
        )
        allow(grom).to receive(:crossbox_choice_cell_area) { |question, choice| [question, choice] }
        pixels = double
        allow(pixels).to receive(:average_cross) do |area|
          area == :cal ? 80 : [30, 250, 20][area[1]]
        end
        allow(pixels).to receive(:average_off_cross) do |area|
          area == :cal ? 250 : [240, 240, 80][area[1]]
        end

        mim.instance_variable_set(:@grom, grom)
        mim.instance_variable_set(:@choxq, [[0, 1, 2]])
        mim.instance_variable_set(:@reg_pixels, pixels)

        expect(mim.marked).to eq [[0]]
      end
    end

    describe '#overlay with crossboxes' do
      it 'uses rectangular overlay geometry' do
        mim = Mimage.allocate
        area = Coord.new(10, h: 8)
        grom = double(crossbox?: true, max_questions: 1, max_choices_per_question: 1)
        allow(grom).to receive(:choice_cell_area).with(0, 0).and_return(area)
        mack = double
        expect(mack).to receive(:respond_to?).with(:outline).and_return(true)
        expect(mack).to receive(:outline).with([area], false)

        mim.instance_variable_set(:@grom, grom)
        mim.instance_variable_set(:@mack, mack)

        mim.overlay(:outline, [[0]])
      end
    end

    describe NPatch do
      it 'distinguishes diagonal marks from filled cell interiors' do
        width = 40
        height = 30
        source = Array.new(width * height, 255)
        (0...height).each do |y|
          (0...width).each do |x|
            source[y * width + x] = 0 if (x - y * width / height).abs <= 1 ||
                                         (x - (width - 1 - y * width / height)).abs <= 1
          end
        end
        cross_patch = NPatch.new(source, width, height)
        area = Coord.new(width, h: height)

        expect(cross_patch.average_cross(area)).to be < cross_patch.average_off_cross(area)

        filled_source = Array.new(width * height, 255)
        (5...height - 5).each do |y|
          (6...width - 6).each do |x|
            filled_source[y * width + x] = 0
          end
        end
        filled_patch = NPatch.new(filled_source, width, height)

        expect(filled_patch.average_off_cross(area)).to be < cross_patch.average_off_cross(area)
      end
    end

    context 'John Doe' do
      let(:img) { sample_img 'jdoe1' }
      let(:fn)  { File.basename(img.image_path) }
      let(:mim) { Mimage.new img.image_path, GridOMR.new(img.grid_path)  }
      describe '#choice_mean_darkness' do
        it 'returns all choices as darkness averaga' do
          d = mim.choice_mean_darkness
          d.each do |q|
            p = q.map do |c|
              c.round
            end.join ' '
            # puts p
          end
        end
      end

      describe 'basics' do
        it 'should be valid' do
          expect(mim.valid?).to be_truthy
        end

        it 'should return the correct regmark coordinates' do
          [:tl, :tr, :br, :bl].each do |corner|
            crn = mim.rm[corner]
            expect(crn[:x]).to be_within(2).of(img.send(corner)[0])
            expect(crn[:x]).to be_within(2).of(img.send(corner)[0])
          end
        end

        xit 'writes all cell values to a text file' do
          d=Dir['spec/samples/syst/*.jpg']
          d.each do |f|
            fname = File.basename f, '.jpg'
            m = Mimage.new "spec/samples/syst/#{fname}.jpg", qna, GridOMR.new('spec/samples/grid.yml')
            puts fname
            File.open("spec/out/text/#{fname}.txt",'w') do |f|
              f.puts "ink:#{m.send :ink_black}"
              f.puts "drk:#{m.send :darkest_cell_mean}"
              f.puts "pap:#{m.send :paper_white}"
              f.puts "cal:#{m.send :cal_cell_mean}"
              f.puts "cho:#{m.send :choice_threshold}"
              100.times do |q|
                5.times do |c|
                  f.puts m.send('choice_cell_averages')[q, c]
                end
              end
            end
          end
        end
      end
    end
  end
end
