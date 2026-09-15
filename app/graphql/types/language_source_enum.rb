module Types
  class LanguageSourceEnum < Types::BaseEnum
    graphql_name 'LanguageSource'
    description 'The registry that publishes a language code'

    Language::SOURCE_NAMES.each do |source, name|
      value source.upcase, name, value: source
    end
  end
end
