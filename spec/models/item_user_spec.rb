require 'rails_helper'
require Rails.root.join 'spec/concerns/rejects_contact_grants_spec.rb'

describe ItemUser, type: :model do
  it_behaves_like 'rejects contact grants', :item
end
