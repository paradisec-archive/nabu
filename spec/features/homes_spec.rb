require 'rails_helper'

describe 'home page' do
  it 'exists' do
    visit root_path
    expect(page.status_code).to be(200)
    expect(page).to have_content('Welcome to the catalog of the PARADISEC collection')
  end
end
