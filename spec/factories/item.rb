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
    subject_language
    content_language
    country
    discourse_type
    collection
    originated_on Time.now
  end
end
