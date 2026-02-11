# ## Schema Information
#
# Table name: `users`
# Database name: `primary`
#
# ### Columns
#
# Name                            | Type               | Attributes
# ------------------------------- | ------------------ | ---------------------------
# **`id`**                        | `bigint`           | `not null, primary key`
# **`address`**                   | `string(255)`      |
# **`address2`**                  | `string(255)`      |
# **`admin`**                     | `boolean`          | `default(FALSE), not null`
# **`collector`**                 | `boolean`          | `default(FALSE), not null`
# **`confirmation_sent_at`**      | `datetime`         |
# **`confirmation_token`**        | `string(255)`      |
# **`confirmed_at`**              | `datetime`         |
# **`contact_only`**              | `boolean`          | `default(FALSE)`
# **`country`**                   | `string(255)`      |
# **`current_sign_in_at`**        | `datetime`         |
# **`current_sign_in_ip`**        | `string(255)`      |
# **`email`**                     | `string(255)`      |
# **`encrypted_password`**        | `string(255)`      | `default(""), not null`
# **`failed_attempts`**           | `integer`          | `default(0)`
# **`first_name`**                | `string(255)`      | `not null`
# **`last_name`**                 | `string(255)`      |
# **`last_sign_in_at`**           | `datetime`         |
# **`last_sign_in_ip`**           | `string(255)`      |
# **`locked_at`**                 | `datetime`         |
# **`party_identifier`**          | `string(255)`      |
# **`phone`**                     | `string(255)`      |
# **`remember_created_at`**       | `datetime`         |
# **`reset_password_sent_at`**    | `datetime`         |
# **`reset_password_token`**      | `string(255)`      |
# **`rights_transfer_reason`**    | `string(255)`      |
# **`sign_in_count`**             | `integer`          | `default(0)`
# **`terms_accepted_at`**         | `datetime`         |
# **`unconfirmed_email`**         | `string(255)`      |
# **`unikey`**                    | `string(255)`      |
# **`unlock_token`**              | `string(255)`      |
# **`created_at`**                | `datetime`         | `not null`
# **`updated_at`**                | `datetime`         | `not null`
# **`rights_transferred_to_id`**  | `integer`          |
#
# ### Indexes
#
# * `index_users_on_confirmation_token` (_unique_):
#     * **`confirmation_token`**
# * `index_users_on_email` (_unique_):
#     * **`email`**
# * `index_users_on_reset_password_token` (_unique_):
#     * **`reset_password_token`**
# * `index_users_on_rights_transferred_to_id`:
#     * **`rights_transferred_to_id`**
# * `index_users_on_unikey` (_unique_):
#     * **`unikey`**
# * `index_users_on_unlock_token` (_unique_):
#     * **`unlock_token`**
#
require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#terms_accepted?' do
    let(:user) { create(:user, terms_accepted_at: terms_accepted_at) }

    context 'when terms_accepted_at is nil' do
      let(:terms_accepted_at) { nil }

      it 'returns false' do
        expect(user.terms_accepted?).to be false
      end
    end

    context 'when terms were accepted recently' do
      let(:terms_accepted_at) { 1.day.ago }

      it 'returns true' do
        expect(user.terms_accepted?).to be true
      end
    end

    context 'when terms were accepted more than 3 months ago' do
      let(:terms_accepted_at) { 4.months.ago }

      it 'returns false' do
        expect(user.terms_accepted?).to be false
      end
    end

    context 'when terms were accepted exactly at the boundary' do
      let(:terms_accepted_at) { 3.months.ago + 1.minute }

      it 'returns true' do
        expect(user.terms_accepted?).to be true
      end
    end
  end

  describe '#accept_terms!' do
    let(:user) { create(:user, terms_accepted_at: nil) }

    it 'sets terms_accepted_at to current time' do
      freeze_time do
        user.accept_terms!
        expect(user.reload.terms_accepted_at).to eq(Time.current)
      end
    end

    it 'persists the change' do
      user.accept_terms!
      expect(user.reload.terms_accepted_at).to be_present
    end
  end
end
