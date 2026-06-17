require 'rails_helper'

# The /users endpoint backs every user-picker. Grant pickers pass exclude_contacts=true so contacts
# (who can never hold a grant) are filtered out; attribution pickers (collector/operator) omit it so
# contacts remain selectable.
describe 'Users picker', type: :request do
  let!(:real_user) { create(:user, first_name: 'Real', last_name: 'Researcher') }
  let!(:contact) { create(:user, :contact_only, first_name: 'Contact', last_name: 'Person') }

  before { sign_in create(:user) }

  def picker_ids(params)
    get users_path, params: params
    JSON.parse(response.body)['results'].map { |r| r['value'] }
  end

  it 'excludes contact-only users from grant pickers' do
    ids = picker_ids(q: 'Person', exclude_contacts: true)

    expect(ids).not_to include(contact.id)
  end

  it 'includes real users in grant pickers' do
    ids = picker_ids(q: 'Researcher', exclude_contacts: true)

    expect(ids).to include(real_user.id)
  end

  it 'includes contact-only users in attribution pickers' do
    ids = picker_ids(q: 'Person')

    expect(ids).to include(contact.id)
  end
end
