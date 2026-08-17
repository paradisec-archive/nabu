require 'rails_helper'

# ## Schema Information
#
# Table name: `languages`
# Database name: `primary`
#
# ### Columns
#
# Name               | Type               | Attributes
# ------------------ | ------------------ | ---------------------------
# **`id`**           | `integer`          | `not null, primary key`
# **`code`**         | `string(255)`      |
# **`east_limit`**   | `float(24)`        |
# **`name`**         | `string(255)`      |
# **`north_limit`**  | `float(24)`        |
# **`retired`**      | `boolean`          |
# **`south_limit`**  | `float(24)`        |
# **`west_limit`**   | `float(24)`        |
#
# ### Indexes
#
# * `index_languages_on_code` (_unique_):
#     * **`code`**
#
describe Language, type: :model do
  it 'rejects a swapped map extent (east < west with a positive east edge)' do
    language = build(:language, west_limit: 154.64, east_limit: 140.8, north_limit: -1.59, south_limit: -12.35)

    expect(language).not_to be_valid
    expect(language.errors[:east_limit]).to be_present
  end

  it 'allows a map extent crossing the antimeridian' do
    language = build(:language, west_limit: 170.0, east_limit: -170.0, north_limit: -1.5, south_limit: -12.25)

    expect(language).to be_valid
  end
end
