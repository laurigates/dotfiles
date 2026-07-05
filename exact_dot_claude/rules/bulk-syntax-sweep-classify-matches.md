# Bulk Syntax Sweep — Classify Matches First

Promoted to a skill: invoke `code-quality-plugin:bulk-sweep-classify` before
any bulk find-replace / syntax-modernization sweep — it buckets every match
into the four categories (genuine target / false positive / out-of-scope
design / immutable record) and verifies against the preserved set, never
literal zero.
