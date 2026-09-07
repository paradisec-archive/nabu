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

**Synonym**:
An alternate name a Source publishes for one of its own Languages. Searchable when choosing a Language; never a Language itself and never evidence on its own that two Languages are Equivalent.
_Avoid_: alias, alternate name, also known as

**Label**:
The one string Nabu shows for a Language wherever a person reads, picks or filters by one: the Name, the Code and the Source, in that order, with Glottolog dialects marked as such. Retired is never part of it. A change to a Label reaches every indexed record that carries it.
_Avoid_: display name, name with code, facet value

**Bounding box**:
Nabu's extent for a Language, and the only geography it keeps. No Source publishes one, so it is the only editable part of a Language. The Refresh fills a box that is empty from the Source's point and never changes one that already exists. Items and collections seed their own boxes from it but keep their own.
_Avoid_: point, coordinates (a Source's published location is a point, not a box)

**Retired**:
A Language whose Source has withdrawn its Code, or no longer publishes it. Recorded on the Language; existing tags stay.

**Reinstated**:
A Retired Language whose Source publishes its Code again. The Refresh clears Retired and reports it; nothing else about the Language or its tags changes.

**Refresh**:
The scheduled pass that brings every Language into line with its Source, regenerates Equivalents, fills empty Bounding boxes and emails a report. Applies what needs no judgement and reports what does.
_Avoid_: import (the one-off hand-run task it replaces), sync

**Run**:
One execution of the Refresh, recorded with the Source versions it read, what it changed and the report it sent. The previous Run is the baseline for what counts as a change.

**Held**:
A Retired Language still tagged on collections or items whose Source gave no single replacement (a split or a merge). Listed in every report until a person re-tags; not a stored state.
_Avoid_: pending change, review queue

**Location warning**:
A report entry noting that a Source's point is far outside a Language's Bounding box. Nothing is changed; a person decides. No point is kept between Runs, so it repeats every Run until someone resolves it.

**Source URI**:
The Source's own web address for a Code. Nabu publishes it wherever a Language is identified outside Nabu, and asserts no other address for the Language.
_Avoid_: archive link, Ethnologue link
