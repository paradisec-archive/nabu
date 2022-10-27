FactoryBot.define do
  factory :language, :aliases => [:subject_language, :content_language] do
    sequence(:code) {|n| "sk#{n}"}
    sequence(:name) {|n| "Language #{n}"}
  end
end
