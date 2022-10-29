require 'rails_helper'

describe 'home page' do
  it 'exists' do
    visit root_path
    page.status_code.should be(200)
    page.should have_content('Welcome to the catalog of the PARADISEC collection')
  end
end
