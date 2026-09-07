FactoryBot.define do
  factory :language, aliases: [:subject_language, :content_language] do
    source { :iso639_3 }
    # Base 26 over the sequence, so every code is the three lowercase letters ISO 639-3 requires.
    sequence(:code) { |n| n.to_s(26).tr('0-9a-p', 'a-z').rjust(3, 'a') }
    sequence(:name) { |n| "Language #{n}" }

    trait :iso639_3 do
      source { :iso639_3 }
    end

    trait :glottolog do
      source { :glottolog }
      sequence(:code) { |n| format('lang%04d', n % 10_000) }
    end

    trait :glottolog_dialect do
      glottolog
      dialect { true }
    end

    trait :austlang do
      source { :austlang }
      sequence(:code) { |n| "C#{n}" }
    end
  end
end
