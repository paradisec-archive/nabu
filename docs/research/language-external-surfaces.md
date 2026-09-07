# What external surfaces accept for non-ISO language codes

Facts gathered for [Language identity on external surfaces](https://github.com/paradisec-archive/nabu/issues/1187), September 2026.

## OLAC

- `olac:code` is restricted to "all active codes for individual languages from any part of ISO 639". No glottocode or AUSTLANG support, no published proposal. https://www.language-archives.org/REC/language/
- Element text may identify a variety alongside a code, and may stand alone when no code exists. https://www.language-archives.org/NOTE/usage/
- Aggregator integrity checks: a code not in ISO 639 (BLC) and a retired code are per-record errors that lower the archive's star rating; `olac:language` with no `olac:code` (MLC) is also an error, so text-only elements must omit the `xsi:type`. https://www.language-archives.org/NOTE/metrics/
- The 2025-26 OLAC revamp (DELAMAN) will index Glottolog and AUSTLANG by mapping from ISO 639, not by accepting their codes. https://www.delaman.org/resources/olac-revamp/

## Glottolog

- Glottolog does not harvest OLAC. None of its reference providers is OLAC; languoid pages link out to language-archives.org and iso639-3.sil.org by ISO code. https://glottolog.org/langdoc/langdocinformation
- Canonical URI: `https://glottolog.org/resource/languoid/id/<glottocode>`, JSON on `Accept: application/json`.

## RIF-CS

- `subject/@type` is `xsd:string`; ARDC's recommended vocabulary is `anzsrc-for`, `anzsrc-seo`, `anzsrc-toa`, `apt`, `gcmd`, `iso639`, `local`, `pont`, `psychit`, `scot` plus Library of Congress source codes. The value is `iso639`, not `iso639-3`. No AUSTLANG or Glottolog value. https://documentation.ardc.edu.au/rda/rif-cs-vocabularies
- `identifier/@type` includes `uri`. `termIdentifier` may carry a URI but Research Data Australia does not use it yet. https://documentation.ardc.edu.au/rda/subject

## RO-Crate and schema.org

- RO-Crate 1.1, 1.2 and the 1.3 draft say nothing about Language entities.
- schema.org `Language` defines no properties of its own; it inherits `name`, `identifier`, `url`, `alternateName`, `sameAs`. `alternateName` is suggested for BCP 47 tags only. https://schema.org/Language
- The LDaCA vocabulary defines `subjectLanguage` (range schema:Language) and nothing for a Language node. `code`, `iso639-3`, `glottologCode`, `austlangCode` in describo data-packs are undefined terms. https://w3id.org/ldac/terms
- describo and LDaCA crates use `https://glottolog.org/resource/languoid/id/<code>` and `https://collection.aiatsis.gov.au/austlang/language/<code>` as `@id`, with `sameAs` arrays matched by name. https://github.com/describo/data-packs

## URIs

| URL | Browser | Non-browser client |
|---|---|---|
| `https://iso639-3.sil.org/code/<code>` | 200, self-declared canonical | 200 |
| `https://glottolog.org/resource/languoid/id/<code>` | 200 | 200 |
| `https://collection.aiatsis.gov.au/austlang/language/<code>` | 301 to `aiatsis.gov.au`, then 200 | 301, 200 |
| `https://www.language-archives.org/language/<code>` | 200, JavaScript app | 200, empty shell |
| `http://www.ethnologue.com/show_language.asp?code=<code>` | 200 page whose script forwards to `/language/<code>/` | 403 |
