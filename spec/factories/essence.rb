FactoryBot.define do
  factory :essence do
    item { build(:item, :with_doi) }
    created_at Date.parse('2015/01/01')

    factory :sound_essence do
      filename 'moo.wav'
      mimetype 'audio/mp3'
      bitrate  128*1024
      samplerate 96_000
      size 5_678_123
      duration 60*3 + 24
      channels 2
    end

    factory :video_essence do
      filename 'cow.mp4'
      mimetype 'video/ogv'
      bitrate  2*1024*1024
      samplerate 44_000
      fps 24
      size 100_678_123
      duration 1*60*60 + 33*60 + 24 + 0.6
      channels 2
    end

    factory :image_essence do
      filename 'cow.png'
      mimetype 'image/png'
      size 1_678_123
    end
  end
end
