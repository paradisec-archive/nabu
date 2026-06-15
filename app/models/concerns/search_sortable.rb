module SearchSortable
  extend ActiveSupport::Concern

  # OpenSearch sorts keyword fields byte-by-byte, so "AA10" would otherwise sort before "AA2".
  # Numeric runs in our identifiers are not zero-padded, so we build a sort key that downcases
  # (case-insensitive) and left-pads each numeric run to a fixed width, making lexicographic
  # order match numeric order. The pad MUST be >= the longest numeric run we hold, otherwise
  # longer numbers sort before shorter ones. Item identifiers carry 11-digit date/sequence runs
  # (e.g. "20041004001"), so 12 covers everything with a digit of headroom. Leading zeros
  # compress away in the index, so the wider pad costs almost nothing in storage.
  NATURAL_SORT_PAD = 12

  class_methods do
    def natural_sort_key(value)
      return if value.nil?

      value.downcase.gsub(/\d+/) { |digits| digits.rjust(NATURAL_SORT_PAD, '0') }
    end
  end
end
