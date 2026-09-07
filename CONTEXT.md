# Nabu

Nabu is PARADISEC's catalogue of collections, items and files, and the metadata that describes them. This glossary covers the language vocabulary; other areas are added as they are settled.

## Language

**Language**:
A taggable row holding exactly one Code from one Source. A Language has no ISO 639-3 code unless its Source is ISO 639-3, and holds no other Source's code. Identified by its own Nabu id.
_Avoid_: languoid, variety, language variety, dialect (as a noun for a row)

**Code**:
What a Source calls a Language: an ISO 639-3 code, a glottocode or an AUSTLANG code. Unique within its Source.

**Source**:
One of the three registries a Code comes from: ISO 639-3, Glottolog, AUSTLANG. Sources are the truth for everything on a Language except its Bounding box.
_Avoid_: code type, registry, authority

**Dialect**:
A Glottolog Language that Glottolog files one level below a language. Nabu records the classification only; no relation to the parent is kept. Distinct from an item's free-text dialect as given.

**Equivalent**:
An advisory suggestion that two Languages from different Sources may denote the same language, carried with the evidence that produced it. Never a stored fact and never confirmed by a person.
_Avoid_: concordance, mapping (as a stored fact), link, sameAs

**Bounding box**:
Nabu's hand-curated extent for a Language. No Source publishes one, so it is the only editable part of a Language. Items and collections seed their own boxes from it but keep their own.
_Avoid_: point, coordinates (a Source's published location is a point, not a box)

**Retired**:
A Language whose Source has withdrawn its Code. Recorded on the Language; existing tags stay.
