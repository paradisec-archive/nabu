-- sqlfluff:indentation:tab_space_size:2

SELECT
  collections.id AS entity_id,
  'Collection' AS entity_type,
  collections.identifier,
  collections.title,
  COUNT(DISTINCT collection_items.id) AS items_count,
  COUNT(DISTINCT collection_essences.id) AS essences_count,
  collections.private
FROM
  collections
LEFT JOIN items AS collection_items
  ON collections.id = collection_items.collection_id
LEFT JOIN essences AS collection_essences
  ON collection_items.id = collection_essences.item_id
GROUP BY collections.id

UNION DISTINCT

SELECT
  items.id AS entity_id,
  'Item' AS entity_type,
  item_collections.identifier,
  item_collections.title,
  0 AS items_count,
  COUNT(DISTINCT item_essences.id) AS essences_count,
  items.private
FROM
  items
LEFT JOIN collections AS item_collections
  ON items.collection_id = item_collections.id
LEFT JOIN essences AS item_essences
  ON items.id = item_essences.item_id
GROUP BY items.id
