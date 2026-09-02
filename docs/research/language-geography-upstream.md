# Upstream geography for Nabu's languages: Glottolog points and Glottography polygons

Research for [#1184](https://github.com/paradisec-archive/nabu/issues/1184), child of
[#1182 Wayfinder: Glottolog and AUSTLANG language codes](https://github.com/paradisec-archive/nabu/issues/1182).
Builds on [languages-current-state.md](languages-current-state.md).

Written 2026-09-03. All counts are measured against the sources listed in [Method](#method), not estimated.

## TL;DR

- **Glottolog** gives a point for every boxless in-use language it knows about: **167 of 180**, and the 13 it
  misses are `zxx`/`und`/`mul`, macrolanguages and codes Glottolog does not carry. CC-BY-4.0.
- **Glottography** gives a language-level polygon for **108 of 180** boxless in-use languages across the four
  datasets combined (**50 of the 62** Australia-linked ones, all from `bowern2021australia`). The two datasets
  that matter for Australia and New Guinea, `bowern2021australia` and `wurm1981pacific`, are **CC-BY-NC-4.0**;
  `asher2007world` and `bowern2012pamanyungan` are CC-BY-4.0.
- Every polygon is keyed by glottocode in a GeoJSON `FeatureCollection`, versioned on Zenodo with a concept DOI
  per dataset. Datasets are young (v1.0 in 2025-10, v2.0 in 2026-02) and one point release renamed the key
  property and then reverted it.
- **Derived bounding boxes drop straight into the existing RO-Crate `geo` node and the map UI with no code
  change; polygons do not.** Both surfaces are box-only end to end.
- The 20 boxless in-use languages nothing covers include the two heaviest-used real ones: Gurindji Kriol
  (`gjr`, 4,113 uses) and Kriol (`rop`, 2,834), plus sign languages. Upstream will not solve those.
- Authors' own caveats: Bowern's boundaries are "approximate and the maps are not suitable for use as evidence
  in Native Title claims"; Bowern and Wurm and Hattori depict time-of-contact / 1981 distributions, not where
  speakers are today. Where Nabu already has a box, the Bowern polygon's box overlaps it with a median IoU of only
  0.25.

## 1. Nabu's boxless languages, measured

A language "lacks a box" when any of `north_limit`, `south_limit`, `east_limit`, `west_limit` is `NULL`. There are
no partial boxes (0 rows with some but not all four limits).

| Set | Count |
|---|---|
| languages in table | 7,788 (71 retired) |
| in use (referenced by at least one `collection_languages` / `item_content_languages` / `item_subject_languages` row) | 1,597 |
| **boxless** | **1,577** |
| boxless and linked to country AU | 194 |
| **boxless and in use** | **180** (19,490 usage rows) |
| **boxless, in use and linked to AU** | **62** |

The issue text says "194 of them Australia-linked and in use". Measured, 194 is the AU-linked boxless count
regardless of use; only 62 of those are in use. The rest of this document uses the in-use sets (180 / 62) as the
denominators.

Where the 180 sit, by Glottolog macroarea of the mapped glottocode: Australia 57, Papunesia 47, Eurasia 47,
Africa 11, South America 3, other 2, unmapped 13.

Usage is very skewed. Of the 19,490 usage rows on boxless languages, 6,007 are `zxx`/`und`/`mul`, 4,113 are
Gurindji Kriol and 2,834 are Kriol. The top 25 are listed in [Appendix A](#appendix-a-top-25-boxless-in-use-languages).

## 2. Glottolog points

Source: `cldf/languages.csv` on `master` of
[glottolog/glottolog-cldf](https://github.com/glottolog/glottolog-cldf), whose README identifies it as
"Glottolog database 5.3 as CLDF". Column semantics from
[`cldf/cldf-metadata.json`](https://github.com/glottolog/glottolog-cldf/blob/master/cldf/cldf-metadata.json):
`Latitude`/`Longitude` are decimals, `Level` is `language|dialect|family`, `Language_ID` is the language-level
parent of a dialect, `Closest_ISO369P3code` is "ISO 639-3 code of the languoid or an ancestor if the languoid is a
dialect".

| Measure | Count |
|---|---|
| languoids | 27,177 |
| with a point | 26,696 |
| distinct ISO 639-3 codes (no duplicates) | 8,184 |

Mapping Nabu ISO code to the languoid whose `ISO639P3code` matches:

| Nabu set | Mapped to a glottocode | Have a Glottolog point |
|---|---|---|
| boxless, all (1,577) | 1,520 | 1,499 |
| **boxless, in use (180)** | **167** | **167** |
| boxless, in use, AU-linked (62) | 60 | 60 |

Every boxless in-use language that maps to a glottocode has a point. The 13 that do not map, with usage:
`zxx` 4,579 · `und` 1,039 · `mul` 389 · `msa` 180 · `wky` 34 · `uun` 25 · `zho` 16 · `mlg` 14 · `est` 5 · `lnw` 5 ·
`bik` 3 · `fas` 2 · `ylb` 2. These are the same special codes, macrolanguages and orphans identified in
languages-current-state.md §3.

Of the 167 mapped, 149 resolve to a `language`-level languoid, 17 to a `dialect` (all but two are Victorian and
Queensland Pama-Nyungan varieties such as Madhi Madhi, Wergaia, Wemba Wemba) and 1 to a `family`
(`sqi` Albanian). For dialects, the analysis below also tries the parent `Language_ID`.

**Sanity check of Nabu's existing boxes against Glottolog points.** 1,412 in-use languages have both a Nabu box
and a Glottolog point; the point falls inside the box for 1,359 (96%). Nabu's boxes and Glottolog's points
broadly agree, which supports the #340 view that Glottolog points look like centroids of similar extents.

Licence and citation: CC-BY-4.0 per the repository
[LICENSE](https://github.com/glottolog/glottolog-cldf/blob/master/LICENSE), README and `.zenodo.json`. README
asks for two citations: the Glottolog edition ("Hammarström, Harald & Forkel, Robert & Haspelmath, Martin & Bank,
Sebastian. 2026. Glottolog 5.3. Leipzig: Max Planck Institute for Evolutionary Anthropology.") and the DOI of the
specific release used. Concept DOI `10.5281/zenodo.3260727`; v5.3 is `10.5281/zenodo.18840967`, published
2026-03-02, one 49.6 MB zip.

Release cadence: 16 tagged releases from v4.0 (2019-06-28) to v5.3 (2026-03-02), roughly two a year (v5.0
2024-03, v5.1 2024-10, v5.2 2025-05, v5.2.1 2025-06, v5.3 2026-03). `RELEASING.md` regenerates the CLDF from a
pinned `glottolog/glottolog` tag and publishes to Zenodo.

## 3. Glottography datasets

### What Glottography is

Per the [organisation profile](https://github.com/Glottography/.github/blob/main/profile/README.md): each dataset
is derived from maps in one source publication; shapes are vectorised, then matched to a Glottolog languoid using
the source's metadata. "Multiple features in the source may be mapped to the same Glottolog languoid." Each
dataset ships three sets of geo-data: the features as depicted in the source, aggregated language-level speaker
areas, and aggregated family-level speaker areas. Reviewed datasets are published in the
[Glottography Zenodo community](https://zenodo.org/communities/glottography). The organisation lists 29 dataset
repositories; the four relevant here are examined below. The accompanying paper is Ranacher, Forkel et al.,
"Glottography: an open-source geolinguistic data platform for mapping the world's languages" (supporting material
dated 2026-01-19, [CITATION.cff](https://github.com/Glottography/supporting-material/blob/main/CITATION.cff)).

### 3.1 Licence and attribution

| Dataset | Licence | Where stated | Source publication licence / note |
|---|---|---|---|
| `bowern2021australia` | **CC-BY-NC-4.0** | LICENSE, `metadata.json`, `.zenodo.json`, Zenodo record | Bowern 2021 Zenodo deposit `10.5281/zenodo.4898185` is itself CC-BY-NC-4.0 |
| `bowern2012pamanyungan` | CC-BY-4.0 | LICENSE, `metadata.json`, `.zenodo.json`, Zenodo record | Figure 1 of Bowern & Atkinson 2012, *Language* 88 |
| `wurm1981pacific` | **CC-BY-NC-4.0** | LICENSE, `metadata.json`, `.zenodo.json`, Zenodo record | ECAI released the scans and GIS data CC-BY (CC-BY-NC for the Taiwan leaves); the intermediate [cldf-datasets/languageatlasofthepacificarea](https://github.com/cldf-datasets/languageatlasofthepacificarea) README says "this derived dataset is licensed in its entirety under a CC-BY-NC license", and Glottography inherits that |
| `asher2007world` | CC-BY-4.0 | LICENSE, `metadata.json`, `.zenodo.json`, Zenodo record | Asher & Moseley 2007, *Atlas of the World's Languages*, 2nd edn, Routledge |

GitHub's licence detector shows `NOASSERTION` for the two NC repositories only because it does not recognise the
CC-BY-NC text; the LICENSE files begin "Attribution-NonCommercial 4.0 International".

Attribution: every README's "How to cite" asks for two citations, the original source and "the derived dataset
using the DOI of the particular released version you were using". Zenodo creator is "The Glottography Consortium".
Release notes give the exact strings, e.g. for `bowern2021australia` v2.0:

> The Glottography Consortium. (2026). Glottography dataset derived from Bowern 2021 "Files for Australian Language
> Locations" (v2.0) [Data set]. Zenodo. https://doi.org/10.5281/zenodo.18613913

Whether PARADISEC's use is "non-commercial" under CC-BY-NC is a policy question for the archive, not something this
research can settle; it is flagged because the two datasets with the best Australian and New Guinea coverage are
the NC ones.

### 3.2 Download format and stability

**Identifiers.** Each dataset has a Zenodo concept DOI (in `metadata.json`) that resolves to the latest version, and
a version DOI per release. Resolved via the Zenodo API on 2026-09-03:

| Dataset | Concept DOI | Latest | Version DOI | Published | Zip size |
|---|---|---|---|---|---|
| `bowern2021australia` | 10.5281/zenodo.17334089 | v2.0.2 | 10.5281/zenodo.18777605 | 2026-02-25 | 1.4 MB |
| `bowern2012pamanyungan` | 10.5281/zenodo.17333459 | v2.0 | 10.5281/zenodo.18613855 | 2026-02-11 | 74 KB |
| `wurm1981pacific` | 10.5281/zenodo.17342179 | v2.0 | 10.5281/zenodo.18643982 | 2026-02-14 | 87 MB |
| `asher2007world` | 10.5281/zenodo.15287257 | v2.0 | 10.5281/zenodo.18613195 | 2026-02-11 | 157 MB |

The Zenodo file is a snapshot of the GitHub repository (`Glottography/<repo>-vX.Y.zip`), so the same files are also
fetchable from GitHub at the tag, e.g.
`https://raw.githubusercontent.com/Glottography/bowern2021australia/v2.0.2/cldf/languages.geojson`.

**Layout.** All four are [CLDF Generic](https://github.com/cldf/cldf/tree/master/modules/Generic) datasets under
`cldf/` (`asher2007world` has two: `cldf/traditional/` and `cldf/contemporary/`). The files that matter:

- `languages.csv` (CLDF LanguageTable). One row per Glottolog languoid the dataset covers. `ID` = `Glottocode`;
  `Glottolog_Languoid_Level` is `language`, `dialect` or `family`; `Family` is the top-level family name;
  `Speaker_Area` names the GeoJSON file holding the aggregated shape (`languages`, `dialects` or `families`);
  `Feature_IDs` lists the source features that were aggregated. `Latitude`/`Longitude` are copied from Glottolog.
  **`ISO639P3code` is empty in every row of every dataset** (0 of 426 / 8 / 2,935 / 4,729 / 4,251), so the join
  must go through Glottolog's ISO to glottocode map.
- `contributions.csv` (ContributionTable). One row per source feature with its `Glottocode` ("a Glottolog languoid
  most closely matching the linguistic entity described by the feature"), `Year` (a year or `traditional`, meaning
  "the time of contact with European maritime powers") and the map it came from.
- `media.csv` lists the GeoJSON files: `features.geojson` (shapes as drawn in the source), `languages.geojson`
  ("Speaker areas aggregated for Glottolog language-level languoids"), `families.geojson`, and for
  `bowern2021australia` and `wurm1981pacific` also `dialects.geojson`.

**GeoJSON.** `languages.geojson` is a `FeatureCollection`; each feature's `properties["cldf:languageReference"]` is
the glottocode, alongside `title`, `family`, `fill`, `fill-opacity`. Geometries are `MultiPolygon` (all 326 in
`bowern2021australia`; 1,673 of 1,921 in `wurm1981pacific`; 4,246 of 4,500 in `asher2007world/traditional`), the
rest `Polygon`. `bowern2021australia` v2.0.2 declares `crs` `urn:ogc:def:crs:OGC:1.3:CRS84`; `wurm1981pacific`
v2.0 has no `crs` member (RFC 7946 default, WGS 84). File sizes: `bowern2021australia` 0.9 MB, `wurm1981pacific`
13.9 MB, `asher2007world/traditional` 53 MB.

**Versioning and stability.** Every dataset went v1.0 (2025-04 to 2025-10) to v2.0 (2026-02) within months, and
each has had geometry-fix point releases. `bowern2021australia` has five releases in five months:
v1.0 (2025-10-12), v1.01 "Fixed invalid geometries" (2026-01-30), v2.0 (2026-02-11), v2.0.1 "Removed unintended
Z coordinates from GeoJSON files; geometries now correctly use EPSG:4326 (2D)" (2026-02-25), v2.0.2 (same day):

> When removing the Z-coordinate (see previous release), sf::st_read() sanitised field names in GeoJSON files,
> automatically replacing `:` with `.`. These changes were subsequently reversed.

That is, v2.0.1 shipped with the key property renamed to `cldf.languageReference`. Any importer should pin a
version DOI and assert the property name.

Glottocodes are tied to a Glottolog version: `RELEASING.md` in each repo rebuilds with
`cldfbench makecldf ... --glottolog-version v5.2`, and the CLDF README's `prov:wasDerivedFrom` records Glottolog
v5.2 for the current releases, while Glottolog itself is at 5.3. The pyglottography README states the intent:
"Since the Glottolog language catalog is released in a new version about twice a year, it is necessary to be able
to recreate a Glottography dataset with updated Glottocodes." Expect at least one Glottography release per dataset
per Glottolog release.

Programmatic access exists but is not needed: [`Rglottography`](https://github.com/Glottography/Rglottography)
ships a `registry.json` of concept DOIs and downloads from Zenodo; [`pyglottography`](https://github.com/Glottography/pyglottography)
is for curating datasets, not consuming them.

### 3.3 Coverage of Nabu's boxless in-use languages

Method: map each Nabu ISO code to its Glottolog languoid (§2). A dataset covers a language **directly** when its
`languages.csv` has a row for that glottocode (or, for the 17 dialect-level codes, for the dialect itself or its
`Language_ID` parent) at `language` or `dialect` level, which means `languages.geojson`/`dialects.geojson` has a
shape for it. It covers a language **by family only** when no such row exists but one of the glottocode's
ancestors (Glottolog `classification` parameter from `values.csv`) has a `family`-level row, i.e. only a
`families.geojson` shape contains it. Direct coverage is the headline; family-only is reported separately because
it is usually useless (see below).

Denominators: all boxless in-use languages 180; AU-linked 62; Glottolog macroarea Papunesia 47 (this is the
"Pacific" set; note two AU-linked languages, Fiji Hindi and Unserdeutsch, are Papunesia and 57 of the 62 are
macroarea Australia).

| Dataset (version) | Rows in `languages.csv` (language / dialect / family) | Direct: all 180 | Direct: AU-linked 62 | Direct: Papunesia 47 | Family-only: all 180 |
|---|---|---|---|---|---|
| `bowern2021australia` (v2.0.2) | 426 (326 / 78 / 22) | **50** | **50** | 0 | 3 |
| `bowern2012pamanyungan` (v2.0) | 8 (7 / 0 / 1) | 1 | 1 | 0 | 42 |
| `wurm1981pacific` (v2.0) | 2,935 (1,921 / 916 / 98) | 50 | 19 | **28** | 94 |
| `asher2007world/traditional` (v2.0) | 4,729 (4,500 / 0 / 229) | **80** | 28 | 25 | 80 |
| `asher2007world/contemporary` (v2.0) | 4,251 (4,062 / 0 / 189) | 50 | 0 | 25 | 104 |
| **Union, direct** | | **108** | **50** | **29** | |
| Union, direct or family | | 160 | 57 | 47 | |
| Covered by nothing | | 20 | 5 | 0 | |

Usage-weighted, the 108 directly covered languages account for 2,230 of the 19,490 usage rows on boxless
languages; direct-or-family reaches 8,942.

Observations:

- **Australia.** `bowern2021australia` is the only dataset that matters: it directly covers 50 of 62 AU-linked
  languages (50 of the 57 with macroarea Australia), and nothing in Wurm or Asher covers an AU-linked language
  that Bowern does not. The 12 AU-linked misses are Gurindji Kriol (`gjr`, 4,113 uses; Glottolog classifies it as
  a Mixed Language), Kriol (`rop`, 2,834; classified under Pacific Creole English), Auslan (`asf`, 85),
  Australian Aboriginal Sign Language (`asw`, 33), Fiji Hindi (`hif`, 70), Manangkari (`znk`, 52; Glottolog
  "Unattested"), Torres Strait Creole (`tcs`, 15), Hmong Njua (`hnj`, 7), Unserdeutsch (`uln`, 7), Manda
  (`zma`, 1), and the two codes Glottolog lacks, Wangkayutyuru (`wky`, 34) and Lanima (`lnw`, 5). Bowern's
  polygons are pre-contact language areas, so creoles, mixed languages and sign languages are out of scope by
  design.
- **Pacific.** For the 47 Papunesia languages, `wurm1981pacific` directly covers 28 and `asher2007world` 25, 29
  combined. The 18 Papunesia misses are mostly lingua francas and contact languages (Indonesian 1,132 uses,
  Papuan Malay, Filipino, Fiji Hindi, Unserdeutsch), retired codes, and a handful of small Sepik languages
  (Tapei, Andai, Abu', Ambrak, Yangum Mon, Bouni, Belait). Nasal (`nsy`, 329) and Nama (`nmx`, 148) are also
  missed.
- **Elsewhere.** Of the 47 Eurasia languages only 19 are directly covered (17 by Asher). Phola (`ypg`, 1,313
  uses) is not.
- **Family-only hits are not usable as language extents.** For `wurm1981pacific` the 94 family-only hits match,
  at the smallest containing family, a group with a median of 380 language-level members (Pama-Nyungan 26 hits,
  Sino-Tibetan 20, Indo-European 16, Austronesian 9); only 4 hits are against a family of 10 or fewer languages
  (Arafundi, Yangmanic, Mangarrayi-Maran). `asher2007world/traditional` is the same shape (median 380). The
  `bowern2012pamanyungan` `families.geojson` contains a single feature, all of Pama-Nyungan, so its 42
  family-only hits are that one polygon.
- **Pama-Nyungan subgroup polygons.** `bowern2012pamanyungan` is described as "non-overlapping speaker areas for
  major current subgroups of Pama-Nyungan"; the 29 subgroup shapes are in its `features.geojson`, keyed to
  subgroup glottocodes (Arandic `aran1267`, Wati `wati1241`, Yolngu `yuul1239`, ...). 40 of the 60 AU-linked
  boxless in-use languages with a glottocode sit under one of those subgroups, but every one of them is already
  directly covered by `bowern2021australia`, so the subgroup file adds nothing for this set.
- No dataset had a dialect-level shape whose parent language row was missing, so the dialect handling above never
  changed a count.

The per-language table (code, name, usage, AU flag, glottocode, level, macroarea, point, datasets covering
directly / by family) was produced as a CSV during this research and is reproducible from the script in
[Method](#method); the 25 heaviest-used rows are in Appendix A.

### 3.4 Derived bounding boxes

Taking the envelope of each `languages.geojson` feature for the directly covered languages:

| Dataset | Direct hits with a shape | Boxes spanning the antimeridian | Median box W x H (degrees) | Max multipolygon parts |
|---|---|---|---|---|
| `bowern2021australia` | 50 | 0 | 2.16 x 2.06 | 2 |
| `wurm1981pacific` | 50 | 0 | 0.82 x 0.84 | 17 |
| `asher2007world/traditional` | 80 | 0 | 0.89 x 0.78 | 23 |

`wurm1981pacific` clips at exactly +/-180 rather than wrapping, so a Fijian or Tuvaluan-style straddling shape
would come out as two parts and a 360-degree-wide envelope; none of Nabu's boxless hits does.

How well would such boxes agree with what PARADISEC has chosen where it has chosen? For in-use languages that
already have a Nabu box and also have a shape in the dataset:

| Dataset | Languages compared | Boxes intersect | Polygon-box centre inside Nabu box | Median IoU |
|---|---|---|---|---|
| `bowern2021australia` | 130 | 121 | 70 | 0.25 |
| `wurm1981pacific` | 974 | 950 | 830 | 0.59 |
| `asher2007world/traditional` | 1,110 | 1,064 | 909 | 0.52 |

Bowern's time-of-contact areas are consistently larger and more offset than PARADISEC's boxes (Nabu's median box
for those 130 languages is 0.91 x 0.80 degrees). Wurm and Asher agree with Nabu much better. This matches the
#340 concern that PARADISEC's coordinates sometimes deliberately differ from a language's traditional area (recording
locations, diaspora, movement).

## 4. Can Nabu use polygons or derived boxes?

### RO-Crate `geo`

`app/views/api/v1/oni/object_meta_item.json.jb:140-153` (and the collection equivalent at
`object_meta_collection.json.jb:106-118`) attach `geo` to the `Language` node only when all four limits are
present, pointing at a `Geometry` node built by `item_geometry_json` (`object_meta_item.json.jb:72-91`):

- `@id` is `#geo-<west>,<south>-<east>,<north>`, i.e. the box coordinates are the identity;
- `asWKT` is a five-point `POLYGON((...))` built from the limits after `normalised_extent`
  (`app/helpers/application_helper.rb:192-200`) has handled antimeridian crossing and swapped extents;
- the context maps `Geometry`/`asWKT` to GeoSPARQL (`object_meta_item.json.jb:327`).

**Derived boxes**: zero code change. Populate the four `languages` columns and the existing code emits them.

**Polygons**: representable in principle (GeoSPARQL `asWKT` accepts any WKT literal, including `MULTIPOLYGON`),
but nothing in Nabu can carry one. The `languages` table has only four `float(24)` columns on MySQL
(`app/models/language.rb` schema comment, `config/database.yml` adapter `mysql2`); `HasBoundaries`
(`app/models/concerns/has_boundaries.rb`) and the `@id` scheme assume a box; and a Wurm or Asher language shape
can have up to 17 or 23 parts, which would be inlined into the RO-Crate of every item that references the
language. The same geometry is also emitted per item/collection for places, so a polygon path is a new feature
(geometry storage, a WKT serialiser, a new `@id` scheme), not an extension of the current one.

### Map UI

`app/javascript/custom/maps.js` is the only map code. It draws one `google.maps.Rectangle` from
`north/south/east/west_limit` (`update_map`, lines 73-110), and "set map from language" (`set_map_bounds_from_ajax`,
lines 16-58) fetches `/languages/:id` JSON, reads the four limits and extends a `LatLngBounds` with them before
writing the union back into the four hidden fields. `LanguagesController#show` (`app/controllers/languages_controller.rb`)
just renders the model, limits included. ActiveAdmin (`app/admin/languages.rb`) edits the four limits and shows the
same `.map` rectangle.

**Derived boxes**: zero code change; they flow through the same JSON. **Polygons**: would need a polygon or GeoJSON
data-layer on the language admin page and a display-only path elsewhere, and the editor's "set map from language"
semantics (union box) would still reduce them to a box anyway.

### Implication

If the aim is to fill the 1,577 empty boxes, the path of least resistance is derive-a-box-from-upstream, not
adopt-polygons. That gets 108 of the 180 in-use gaps (50 of 62 AU) from Glottography, and a point-derived box could
cover the remaining 59 mapped ones from Glottolog if a point-to-box convention is acceptable. Both remain
PARADISEC-editable in ActiveAdmin afterwards, which preserves the #340 position that PARADISEC's boxes are
curatorial choices.

## 5. Quality caveats the authors state

- **Bowern 2021** (Zenodo `10.5281/zenodo.4898185` description): locations are "as far as can be determined, as
  of European settlement"; "Boundaries are approximate and the maps are not suitable for use as evidence in Native
  Title claims." The deposit also carries "AIATSIS codes" and "ISO-639 codes" in its language list
  (`Chirila Language Codes.xlsx`), which the Glottography derivative does not surface but which is relevant to
  #1182's AUSTLANG concordance question.
- **Glottography, all datasets** (organisation README): a feature is matched to "a Glottolog languoid most closely
  matching" it; multiple source features may map to one languoid. `bowern2021australia` RELEASING.md publishes its
  Glottolog-distance outliers: nine language areas whose Glottolog point is more than one grid degree away, up to
  `ayer1246` 4.00 and `kung1258` 4.08 (roughly 400 km).
- **asher2007world** (VALIDATION.md): of 4,489 speaker areas matched to a Glottolog language with a point, 2,902
  had distance 0 and 2,575 contained the point; the largest distance was 11.24 grid units ("about 1,200 km ... seems
  suspicious"), and after an allowlist of explained cases "there are no unexplained distances > 2 grid units, i.e.
  about 200 km". The *traditional* set is time-of-contact only for the Americas and Australia; for other
  macroareas it is "taking current distribution as proxy for time-of-contact data". Where the atlas assigns one
  polygon to several languages, the build merges them to "the smallest Glottolog group containing all matched
  languoids", so some shapes are keyed to subgroups rather than languages. A third of its languages come from Wurm
  and Hattori.
- **wurm1981pacific**: source maps are from 1981/83. The build script (`cldfbench_wurm1981pacific.py`) documents
  digitisation gaps in the ECAI data it inherits: "Andaman Islands/Nicobar Islands: not digitized at all",
  "Batan Islands: Some polygons have not been digitized", "Miriam on Darnsley Island missing", Kai and Aru Islands
  "all (wrongly) mapped to Bazaar Malay / BIAK", plus 30-odd obsolete features removed and inset maps re-digitised
  by hand. The upstream ECAI CLDF README says the digitised data "lacking proper identification of language
  varieties ... was largely unusable" before Glottolog matching.
- **bowern2012pamanyungan**: subgroup-level only, "derived from Figure 1" of a phylogenetics paper; 7 language
  rows and one family.
- **Glottolog**: a point is a single coordinate; the level description in the CLDF README defines a language-level
  languoid as a "languoid with extended metadata such as coordinates", nothing about extent.
- **AUSTLANG** (for completeness): 835 of the 1,204 records in the data.gov.au datastore have non-zero
  latitude and longitude; 369 do not. Points only, and no ISO or glottocode column, so it cannot be counted against
  Nabu's set by code (see languages-current-state.md §3 for the name-matching results).

## Method

- Nabu: `bin/rails runner` via `nabu_run` against the development database on 2026-09-03, exporting
  `id, code, name, retired, usage_count, in_au, north, south, east, west` for all rows. `usage_count` is the sum
  of `collection_languages` + `item_content_languages` + `item_subject_languages` rows; `in_au` is membership in
  `Country.find_by(code: 'AU').languages`. Codebase read at `d06bd594`.
- Glottolog: `cldf/languages.csv` and the `classification` rows of `cldf/values.csv` from
  `glottolog/glottolog-cldf` `master` (README: Glottolog 5.3). Lineage = the slash-separated glottocode path in
  `classification`.
- Glottography: `cldf/languages.csv`, `cldf/contributions.csv` and `cldf/languages.geojson` (plus
  `families.geojson` for `bowern2012pamanyungan`) fetched from GitHub at tags `bowern2021australia@v2.0.2`,
  `bowern2012pamanyungan@v2.0`, `wurm1981pacific@v2.0`, `asher2007world@v2.0` (both `traditional` and
  `contemporary`). Licences from LICENSE, `metadata.json`, `.zenodo.json` and the Zenodo API
  (`/api/records/<concept id>`); release notes from the GitHub releases API.
- AUSTLANG: `https://data.gov.au/data/api/3/action/datastore_search?resource_id=e9a9ea06-d821-4b53-a05f-877409a1a19c&limit=2000`
  (1,204 records).
- Bounding boxes are the min/max of all coordinates in a feature's geometry; IoU is on those envelopes and Nabu's
  box, skipping Nabu boxes with `west > east`.
- glottography.org was unreachable from the research machine; all Glottography facts come from the GitHub
  repositories and Zenodo.

## Appendix A: top 25 boxless in-use languages

| Code | Name | Usage | AU | Glottocode | Macroarea | Point | Direct polygon in | Family-only in |
|---|---|---|---|---|---|---|---|---|
| zxx | No linguistic content | 4,579 | | | | no | | |
| gjr | Gurindji Kriol | 4,113 | AU | guri1249 | Australia | yes | | |
| rop | Kriol | 2,834 | AU | krio1252 | Australia | yes | | asher (both), wurm |
| ypg | Phola | 1,313 | | phol1237 | Eurasia | yes | | asher (both), wurm |
| ind | Indonesian | 1,132 | | indo1316 | Papunesia | yes | | asher (both), wurm |
| und | Undetermined language | 1,039 | | | | no | | |
| rxd | Ngardi | 483 | AU | ngar1288 | Australia | yes | bowern2021, wurm, asher/trad | pamanyungan, asher/contemp |
| mul | Multiple languages | 389 | | | | no | | |
| nsy | Nasal | 329 | | nasa1239 | Papunesia | yes | | asher (both), wurm |
| dmw | Mudburra | 317 | AU | mudb1240 | Australia | yes | bowern2021, asher/trad | pamanyungan, wurm, asher/contemp |
| msa | Malay | 180 | | | | no | | |
| axl | Aranda, Lower Southern | 151 | AU | lowe1436 | Australia | yes | bowern2021, asher/trad | pamanyungan, wurm, asher/contemp |
| nmx | Nama | 148 | | nama1266 | Papunesia | yes | | asher (both), wurm |
| pmy | Malay, Papuan | 107 | | papu1250 | Papunesia | yes | | asher (both), wurm |
| fil | Filipino | 106 | | fili1244 | Papunesia | yes | | asher (both), wurm |
| zlm | Malay | 103 | | mala1479 | Eurasia | yes | wurm | asher (both) |
| lle | Lele | 103 | | lele1270 | Papunesia | yes | wurm | asher (both) |
| ksu | Khamyang | 99 | | kham1291 | Eurasia | yes | | asher (both), wurm |
| gnl | Gangulu | 91 | AU | gang1268 | Australia | yes | bowern2021 | pamanyungan, wurm, asher (both) |
| asf | Auslan | 85 | AU | aust1271 | Australia | yes | | |
| vwa | Awa | 84 | | awac1238 | Eurasia | yes | asher (both), wurm | |
| hif | Fiji Hindi | 70 | AU | fiji1242 | Papunesia | yes | | asher (both), wurm |
| adz | Adzera | 66 | | adze1240 | Papunesia | yes | asher (both), wurm | |
| try | Turung | 53 | | turu1249 | Eurasia | yes | | asher (both), wurm |
| znk | Manangkari | 52 | AU | mana1248 | Australia | yes | | bowern2021, wurm, asher (both) |
