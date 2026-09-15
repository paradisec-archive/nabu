# frozen_string_literal: true

module Types
  class LanguageSourceEnum < Types::BaseEnum
    graphql_name 'LanguageSource'
    description 'The Source a language code comes from'

    Language::SOURCE_NAMES.each do |source, source_name|
      value source.upcase, source_name, value: source
    end
  end
end
