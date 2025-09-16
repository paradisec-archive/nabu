FactoryBot.define do
  factory :oauth_application, class: 'Doorkeeper::Application' do
    name { 'Test Application' }
    uid { SecureRandom.hex }
    secret { SecureRandom.hex }
    redirect_uri { 'urn:ietf:wg:oauth:2.0:oob' }
    scopes { 'public' }
    confidential { true }

    factory :oauth_application_with_admin_scope do
      scopes { 'public admin' }
    end

    factory :oauth_application_with_read_write_scope do
      scopes { 'public read_write' }
    end
  end

  factory :oauth_access_token, class: 'Doorkeeper::AccessToken' do
    association :application, factory: :oauth_application
    token { SecureRandom.hex }
    scopes { 'public' }
    created_at { 1.hour.ago }

    # Machine-to-machine token with public scope
    factory :m2m_public_token do
      resource_owner_id { nil }
      scopes { 'public' }
    end

    # Machine-to-machine token with admin scope
    factory :m2m_admin_token do
      resource_owner_id { nil }
      scopes { 'public admin' }
      association :application, factory: :oauth_application_with_admin_scope
    end

    # User token with public scope
    factory :user_public_token do
      resource_owner_id { create(:user).id }
      scopes { 'public' }
    end

    # User token with read_write scope
    # factory :user_read_write_token do
    #   resource_owner_id { create(:user).id }
    #   scopes { 'public read_write' }
    #   association :application, factory: :oauth_application_with_read_write_scope
    # end

    # Admin user token with read_write scope
    factory :admin_user_public_token do
      resource_owner_id { create(:admin_user).id }
      scopes { 'public read_write' }
      association :application, factory: :oauth_application_with_read_write_scope
    end
  end
end
