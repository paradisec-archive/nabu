# PROTOTYPE (#1185) — exports every Nabu language with usage counts for concordance.py.
# Run: bin/nabu_run bin/rails runner docs/research/language-concordance/export_nabu_languages.rb
# Writes tmp/nabu-languages.csv (the container mounts the checkout at /rails).
require 'csv'

au_ids = Country.find_by(code: 'AU')&.languages&.pluck(:id)&.to_set || Set.new
collection_uses = CollectionLanguage.group(:language_id).count
content_uses = ItemContentLanguage.group(:language_id).count
subject_uses = ItemSubjectLanguage.group(:language_id).count

CSV.open('/rails/tmp/nabu-languages.csv', 'w') do |csv|
  csv << %w[id code name retired usage_count collection_uses content_uses subject_uses in_au has_box north south east west]
  Language.order(:code).find_each do |l|
    c = collection_uses[l.id].to_i
    ic = content_uses[l.id].to_i
    is = subject_uses[l.id].to_i
    has_box = [l.north_limit, l.south_limit, l.east_limit, l.west_limit].none?(&:nil?)
    csv << [l.id, l.code, l.name, l.retired, c + ic + is, c, ic, is, au_ids.include?(l.id), has_box, l.north_limit, l.south_limit, l.east_limit, l.west_limit]
  end
end

puts "rows=#{Language.count}"
