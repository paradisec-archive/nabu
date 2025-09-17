# frozen_string_literal: true

module Types
  class EmailUserType < Types::BaseObject
    field :email, String
    field :first_name, String, null: true
    field :last_name, String, null: true
  end
end
