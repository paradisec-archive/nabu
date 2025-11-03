-- sqlfluff:indentation:tab_space_size:2

SELECT
  collections.id AS entity_id,
  'Collection' AS entity_type,
  NULL AS member_of,
  collections.title,
  COUNT(DISTINCT collection_items.id) AS items_count,
  COUNT(DISTINCT collection_essences.id) AS essences_count,
  collections.private,
  GROUP_CONCAT(DISTINCT collection_essences.mimetype ORDER BY collection_essences.mimetype SEPARATOR ',') AS media_types,
  DATE(collections.created_at) AS originated_on
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
  item_collections.identifier AS member_of,
  items.title,
  0 AS items_count,
  COUNT(DISTINCT item_essences.id) AS essences_count,
  items.private,
  GROUP_CONCAT(DISTINCT item_essences.mimetype ORDER BY item_essences.mimetype SEPARATOR ',') AS media_types,
  items.originated_on
FROM
  items
LEFT JOIN collections AS item_collections
  ON items.collection_id = item_collections.id
LEFT JOIN essences AS item_essences
  ON items.id = item_essences.item_id
GROUP BY items.id

UNION DISTINCT

SELECT
  essences.id AS entity_id,
  'Essence' AS entity_type,
  essence_items.identifier AS member_of,
  essences.filename,
  0 AS items_count,
  0 AS essences_count,
  essence_items.private,
  essences.mimetype AS media_types,
  essence_items.originated_on
FROM
  essences
LEFT JOIN items AS essence_items
  ON essences.item_id = essence_items.id
GROUP BY essences.id
