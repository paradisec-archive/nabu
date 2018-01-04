NabuSchema = GraphQL::Schema.define do
  query Types::QueryType

  # resolve_type ->(obj, ctx) do
  #   case obj
  #   when Item
  #     Types::Item
  #   when Collection
  #     Types::Collection
  #   when Essence
  #     Types::Essence
  #   else
  #     raise("Don't know how to get the GraphQL type of a #{obj.class.name} (#{obj.inspect})")
  #   end
  # end
end
