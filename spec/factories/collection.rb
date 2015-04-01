FactoryGirl.define do
  factory :collection do
    sequence(:identifier) {|n| "AA#{n}"}
    title 'Collection Title'
    description 'The awesome collection'
    countries {[create(:country)]}
    region 'East Africa'
    north_limit "24.625"
    south_limit "23.99"
    west_limit "121.122"
    east_limit "122.046"
    field_of_research
    university
    collector
    private false
  end
end
