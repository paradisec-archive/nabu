require 'spec_helper'

describe TranscodeEssenceFileService do
  let(:transcode_essence_file_service) do
    TranscodeEssenceFileService.new(item)
  end
  let(:collection) { create(:collection, identifier: collection_identifier) }
  let(:item) { create(:item, collection: collection, identifier: item_identifier) }
  let(:non_existent_file_essence) do
    create(
      :video_essence,
      item: item,
      filename: 'WRONG.mp4',
      mimetype: 'video/mp4'
    )
  end
  let(:video_mp4_essence) do
    create(
      :video_essence,
      item: item,
      filename: 'RB4-Vanuatu_Gasai-P8050224.mp4',
      mimetype: 'video/mp4'
    )
  end
  let(:video_mpeg_essence) do
    create(
      :video_essence,
      item: item,
      filename: 'LD1-v0435-A.mpg',
      mimetype: 'video/mpeg'
    )
  end
  let(:video_quicktime_essence) do
    create(
      :video_essence,
      item: item,
      filename: 'RD1-013-Blaro_11.mov',
      mimetype: 'video/quicktime'
    )
  end
  let(:video_x_dv_essence) do
    create(
      :video_essence,
      item: item,
      filename: 'NT5-StringBand-006.dv',
      mimetype: 'video/x-dv'
    )
  end
  let(:video_x_msvideo_essence) do
    create(
      :video_essence,
      item: item,
      filename: 'RB3-Mwaghavul-Video_Untitled.avi',
      mimetype: 'video/x-msvideo'
    )
  end

  # before do
  #   pending 'Slow test'
  # end

  context 'file referred to by essence object does not exist' do
    let(:collection_identifier) { 'moot' }
    let(:item_identifier) { 'moot' }
    before do
      Essence.destroy_all
      Item.destroy_all
      Collection.destroy_all
      non_existent_file_essence
      item.reload
    end

    it 'does not crash' do
      expect{ transcode_essence_file_service.run }.to_not raise_error
    end

    it 'does not try to create an input movie object' do
      FFMPEG::Movie.should_not_receive(:new)
      transcode_essence_file_service.run
    end
  end

  # public/system/nabu-archive/RB4/Vanuatu_Gasai/RB4-Vanuatu_Gasai-P8050224.mp4
  context 'mp4 essence file exists' do
    let(:collection_identifier) { 'RB4' }
    let(:item_identifier) { 'Vanuatu_Gasai' }
    describe 'created webm essence object' do
      let(:created_essence_object) do
        video_mp4_essence
        item.reload
        TranscodeEssenceFileService.run(item)
        Essence.last
      end

      it 'has a mimetype of video/webm' do
        pending unless File.exist?('public/system/nabu-archive/RB4/Vanuatu_Gasai/RB4-Vanuatu_Gasai-P8050224.mp4')
        # Multiple expects in an `it` because it takes too long to run.
        expect(created_essence_object.filename).to eq('RB4-Vanuatu_Gasai-P8050224.webm')
        expect(created_essence_object.mimetype).to eq('video/webm')
        expect(created_essence_object.bitrate > 0).to be true
        expect(created_essence_object.samplerate > 0).to be true
        expect(created_essence_object.duration > 0).to be true
        expect(created_essence_object.channels > 0).to be true
        expect(created_essence_object.fps > 0).to be true
      end
    end
  end

  # public/system/nabu-archive/LD1/v0435/LD1-v0435-A.mpg
  context 'mpeg essence file exists' do
    let(:collection_identifier) { 'LD1' }
    let(:item_identifier) { 'v0435' }
    describe 'created webm essence object' do
      let(:created_essence_object) do
        video_mpeg_essence
        item.reload
        TranscodeEssenceFileService.run(item)
        Essence.last
      end

      it 'has a mimetype of video/webm' do
        pending unless File.exist?('public/system/nabu-archive/LD1/v0435/LD1-v0435-A.mpg')
        # Multiple expects in an `it` because it takes too long to run.
        expect(created_essence_object.filename).to eq('LD1-v0435-A.webm')
        expect(created_essence_object.mimetype).to eq('video/webm')
        expect(created_essence_object.bitrate > 0).to be true
        expect(created_essence_object.samplerate > 0).to be true
        expect(created_essence_object.duration > 0).to be true
        expect(created_essence_object.channels > 0).to be true
        expect(created_essence_object.fps > 0).to be true
      end
    end
  end

  # public/system/nabu-archive/RD1/013/RD1-013-Blaro_11.mov
  context 'quicktime essence file exists' do
    let(:collection_identifier) { 'RD1' }
    let(:item_identifier) { '013' }
    describe 'created webm essence object' do
      let(:created_essence_object) do
        video_quicktime_essence
        item.reload
        TranscodeEssenceFileService.run(item)
        Essence.last
      end

      it 'has a mimetype of video/webm' do
        pending unless File.exist?('public/system/nabu-archive/RD1/013/RD1-013-Blaro_11.mov')
        # Multiple expects in an `it` because it takes too long to run.
        expect(created_essence_object.filename).to eq('RD1-013-Blaro_11.webm')
        expect(created_essence_object.mimetype).to eq('video/webm')
        expect(created_essence_object.bitrate > 0).to be true
        expect(created_essence_object.samplerate > 0).to be true
        expect(created_essence_object.duration > 0).to be true
        expect(created_essence_object.channels > 0).to be true
        expect(created_essence_object.fps > 0).to be true
      end
    end
  end

  # public/system/nabu-archive/NT5/StringBand/NT5-StringBand-006.dv
  context 'x-dv essence file exists' do
    let(:collection_identifier) { 'NT5' }
    let(:item_identifier) { 'StringBand' }
    describe 'created webm essence object' do
      let(:created_essence_object) do
        video_x_dv_essence
        item.reload
        TranscodeEssenceFileService.run(item)
        Essence.last
      end

      it 'has a mimetype of video/webm' do
        pending unless File.exist?('public/system/nabu-archive/NT5/StringBand/NT5-StringBand-006.dv')
        # Multiple expects in an `it` because it takes too long to run.
        expect(created_essence_object.filename).to eq('NT5-StringBand-006.webm')
        expect(created_essence_object.mimetype).to eq('video/webm')
        expect(created_essence_object.bitrate > 0).to be true
        expect(created_essence_object.samplerate > 0).to be true
        expect(created_essence_object.duration > 0).to be true
        expect(created_essence_object.channels > 0).to be true
        expect(created_essence_object.fps > 0).to be true
      end
    end
  end

  # public/system/nabu-archive/RB3/Mwaghavul/RB3-Mwaghavul-Video_Untitled.avi
  context 'x-msvideo essence file exists' do
    let(:collection_identifier) { 'RB3' }
    let(:item_identifier) { 'Mwaghavul' }
    describe 'created webm essence object' do
      let(:created_essence_object) do
        video_x_msvideo_essence
        item.reload
        TranscodeEssenceFileService.run(item)
        Essence.last
      end

      it 'has a mimetype of video/webm' do
        pending unless File.exist?('public/system/nabu-archive/RB3/Mwaghavul/RB3-Mwaghavul-Video_Untitled.avi')
        # Multiple expects in an `it` because it takes too long to run.
        expect(created_essence_object.filename).to eq('RB3-Mwaghavul-Video_Untitled.webm')
        expect(created_essence_object.mimetype).to eq('video/webm')
        expect(created_essence_object.bitrate > 0).to be true
        expect(created_essence_object.samplerate > 0).to be true
        expect(created_essence_object.duration > 0).to be true
        expect(created_essence_object.channels > 0).to be true
        expect(created_essence_object.fps > 0).to be true
      end
    end
  end
end
