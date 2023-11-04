# frozen_string_literal: true

module Types
  class EmailUserType < Types::BaseObject
    field :email, String

    def self.authorized?(object, context)
      super && context[:viewer].admin?
    end
  end
end
