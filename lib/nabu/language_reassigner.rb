# frozen_string_literal: true

module Nabu
  # Moves every row in a language join table from one language to another, dropping rows that would duplicate an existing link
  class LanguageReassigner
    def initialize(model)
      @model = model
      @parent_key = (model.column_names - %w[id language_id created_at updated_at]).first
    end

    def reassign(old_language, new_language)
      moved = 0

      @model.where(language_id: old_language.id).find_each do |record|
        if @model.exists?(@parent_key => record[@parent_key], language_id: new_language.id)
          record.destroy!
        else
          record.update!(language_id: new_language.id)
        end
        moved += 1
      end

      puts "Updated #{moved} #{@model.table_name}" if moved.positive?
      moved
    end
  end
end
