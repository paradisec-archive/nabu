# frozen_string_literal: true

module Types
  class LanguageSourceEnum < Types::BaseEnum
    graphql_name 'LanguageSource'
    description 'The Source a language code comes from'

    Language::SOURCES.each_value do |source|
      value source.key.upcase, source.name, value: source.key
    end
  end
end
