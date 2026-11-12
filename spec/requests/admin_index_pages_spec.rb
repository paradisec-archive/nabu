require 'rails_helper'

# Renders every index with its filter sidebar, which is where Ransack upgrades tend to break
describe 'Admin index pages', type: :request do
  before { sign_in create(:user, admin: true) }

  ActiveAdmin.application.namespaces[:admin].resources.each do |resource|
    next unless resource.respond_to?(:resource_class) && resource.defined_actions.include?(:index)

    it "renders #{resource.resource_name.route_key}" do
      get "/admin/#{resource.resource_name.route_key}"

      expect(response).to have_http_status(:ok)
    end
  end
end
