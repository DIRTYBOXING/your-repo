# Module 17: Search and Autosuggest

## Title
Implement Search and Autosuggest Service

## Owner
@search

## Files to add/modify
- backend/search/search_service.dart
- backend/search/autosuggest_service.dart
- infra/search/indexer_worker.dart

## APIs required
- GET /search?q={query}&type={content|creator|event}
- GET /search/suggest?q={prefix}

## DB collections / indices
- search_index (documentId, type, text, metadata)
- search_logs (query, userId, timestamp)
- trending_terms (term, score)

## Tests
- Unit: query parsing and ranking heuristics
- Integration: autosuggest latency and relevance with mocked index
- Load: indexing throughput and search latency under load

## Release gate
- p95 search latency within SLA
- Autosuggest returns relevant suggestions for sample queries
- Indexing pipeline processes sample dataset without errors
