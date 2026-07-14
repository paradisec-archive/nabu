class FixSwappedMapExtents < ActiveRecord::Migration[8.1]
  # A handful of records store their map extent reversed (west > east with both
  # edges positive). A genuine antimeridian crossing always has east <= 0, so
  # these can only be swapped entries; they render invalid WKT (longitude > 360)
  # in every RO-Crate that references them. Rows are swapped one at a time
  # because MySQL evaluates `SET a = b, b = a` left to right.
  def up
    %w[languages items collections].each do |table|
      model = Class.new(ActiveRecord::Base) { self.table_name = table }
      model.where('east_limit < west_limit AND east_limit > 0').find_each do |record|
        record.update_columns(west_limit: record.east_limit, east_limit: record.west_limit)
      end
    end
  end

  def down
    # Irreversible: the original rows were corrupt, and nothing distinguishes
    # repaired rows from ones that were always correct.
  end
end
