require 'spec_helper'

# Shared coverage for the four permission grant models. `parent` is the grant's owning
# association (`:collection` or `:item`); the grant is built linking that parent to the user.
RSpec.shared_examples_for 'rejects contact grants' do |parent|
  let(:model) { described_class }
  let(:parent_record) { create(parent) }

  it 'is valid when granted to a real user' do
    grant = model.new(parent => parent_record, user: create(:user))

    expect(grant).to be_valid
  end

  it 'is invalid when granted to a contact-only user' do
    grant = model.new(parent => parent_record, user: create(:user, :contact_only))

    aggregate_failures do
      expect(grant).not_to be_valid
      expect(grant.errors[:user]).to include('cannot be a contact-only user; contacts can be attributed but not granted access')
    end
  end
end
