# Vendored schemas

Fetched 2026-09-17 unless noted. Nokogiri refuses to resolve a schema over the network, so every
import here points at a sibling file.

| File | Source |
| --- | --- |
| `olac.xsd`, `olac-language.xsd`, `olac-role.xsd`, `olac-linguistic-field.xsd`, `olac-linguistic-type.xsd`, `olac-discourse-type.xsd` | <https://www.language-archives.org/OLAC/1.1/> |
| `olac-extension.xsd` | the same, via a 2015 Wayback snapshot (see below) |
| `dc.xsd`, `dcterms.xsd`, `dcmitype.xsd` | <https://www.dublincore.org/schemas/xmls/qdc/2008/02/11/> |
| `xml.xsd` | <https://www.w3.org/2001/xml.xsd> |
| `oai-identifier.xsd` | <https://www.openarchives.org/OAI/2.0/oai-identifier.xsd> |
| `datacite_4.3_schema.json` | DataCite 4.3 |

`language-archives.org` currently serves these files with the host stripped from every absolute URL,
which turns `targetNamespace="http://www.language-archives.org/OLAC/1.1/"` into `"/OLAC/1.1/"`. A
relative target namespace makes `xs:include` fail and matches no real OLAC record, so
`olac-extension.xsd` was taken from a 2015 snapshot instead. The other OLAC files here predate the
breakage and already hold the correct namespace; do not "update" them from the live site.

`dc.xsd` and `dcterms.xsd` import `xml.xsd` by URL upstream; those two `schemaLocation` values are
the only edits to any file.
