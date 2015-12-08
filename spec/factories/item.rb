FactoryGirl.define do
  factory :item do
    sequence(:identifier) {|n| "%03d" % n}
    title 'Title of item'
    description 'The awesome item'
    region 'East Africa'
    collector
    university
    operator
    north_limit "24.625"
    south_limit "23.99"
    west_limit "121.122"
    east_limit "122.046"
    discourse_type
    collection {build(:collection, :with_doi)}
    originated_on Date.today
    created_at Date.parse('2015/01/01')
    private false
    after(:build) do |item|
      item.countries ||= build_list(:country, 1)
      item.subject_languages = item.subject_languages.present? ? item.subject_languages : build_list(:language, 1)
      item.content_languages = item.content_languages.present? ? item.content_languages : build_list(:language, 1)
    end

    trait :with_doi do
      sequence(:doi) {|n| "doi:ITEM#{n}"}
    end
  end
end
