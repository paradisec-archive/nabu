# frozen_string_literal: true

module Types
  class EmailUserType < Types::BaseObject
    field :email, String
    field :first_name, String, null: true, camelize: false
    field :last_name, String, null: true, camelize: false

    def self.authorized?(object, context)
      super && context[:viewer].admin?
    end
  end
end
