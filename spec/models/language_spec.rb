require 'rails_helper'

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
