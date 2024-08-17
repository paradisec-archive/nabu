require 'rails_helper'
require Rails.root.join "spec/concerns/identifiable_by_doi_spec.rb"

describe Collection, type: :model do
  include_examples "identifiable by doi"
end
