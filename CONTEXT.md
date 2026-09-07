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
Nabu's extent for a Language, either Hand-set or Derived. No Source publishes one, so it is the only editable part of a Language. Items and collections seed their own boxes from it but keep their own.
_Avoid_: point, coordinates (a Source's published location is a point, not a box)

**Hand-set box**:
A Bounding box a person chose. Never changed by a Refresh. Editing any box makes it Hand-set.

**Derived box**:
A Bounding box the Refresh wrote from the Source's point because the Language had none. Zero extent. Follows the point if the Source moves it; becomes Hand-set the moment a person edits it.

**Retired**:
A Language whose Source has withdrawn its Code, or no longer publishes it. Recorded on the Language; existing tags stay.

**Refresh**:
The scheduled pass that brings every Language into line with its Source, regenerates Equivalents, fills Derived boxes and emails a report. Applies what needs no judgement and reports what does.
_Avoid_: import (the one-off hand-run task it replaces), sync

**Run**:
One execution of the Refresh, recorded with the Source versions it read, what it changed and the report it sent. The previous Run is the baseline for what counts as a change.

**Held**:
A Retired Language still tagged on collections or items whose Source gave no single replacement (a split or a merge). Listed in every report until a person re-tags; not a stored state.
_Avoid_: pending change, review queue

**Location warning**:
A report entry noting that a Source's point is far outside a Hand-set box. Raised only when the point is new or has moved. Nothing is changed.
