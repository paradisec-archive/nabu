# Vendored data

## chirila-codes.csv

Bowern's hand-curated codes for Australian languages: an AUSTLANG code beside the ISO 639-3 code
and the glottocode for the same language. The Language Refresh seeds Equivalents from it, which is
the only thing it is read for.

- Source: Claire Bowern, _Files for Australian Language Locations_, `Chirila Language Codes.xlsx`,
  [doi:10.5281/zenodo.4898185](https://doi.org/10.5281/zenodo.4898185)
- Licence: CC-BY-NC-4.0
- A fixed 2021 deposit, so the file is vendored rather than fetched, and the file in the repo is
  its own version.
- Taken from the deposit's single sheet: its `AIATSIS_Code`, `ISO639` and `glottolog@id` columns,
  one row per AIATSIS code where the deposit names several, and one row with an empty code where it
  names none. Bowern's trailing `*` and her `?` on an uncertain ISO code are dropped; Nabu asserts
  no confidence beyond naming Chirila as the source of a pair. A code shape neither registry
  publishes is left out, because it can never match a Language.
