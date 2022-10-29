FactoryBot.define do
  factory :collection do
    sequence(:identifier) {|n| "AA#{n}"}
    title { 'Collection Title' }
    description { 'The awesome collection' }
    # countries {[build(:country)]}
    region { 'East Africa' }
    north_limit { '24.625' }
    south_limit { '23.99' }
    west_limit { '121.122' }
    east_limit { '122.046' }
    field_of_research
    university
    collector { create(:user) }
    created_at { Date.parse('2015/01/01') }
    private { false }
    after(:build) do |item|
      # item.countries ||= create_list(:country, 1)
      # item.subject_languages = item.subject_languages.present? ? item.subject_languages : create_list(:language, 1)
      # item.content_languages = item.content_languages.present? ? item.content_languages : create_list(:language, 1)
    end

    trait :with_doi do
      sequence(:doi) {|n| "doi:COLLECTION#{n}"}
    end
  end
end
