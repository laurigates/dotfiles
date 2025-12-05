# ai_docs/ - Curated AI Documentation

This directory contains curated documentation optimized for AI agents. Unlike raw documentation, ai_docs entries are:

1. **Concise** - Only essential information, no marketing or history
2. **Actionable** - Code snippets that can be directly used
3. **Gotcha-Aware** - Common pitfalls documented with solutions
4. **Version-Specific** - Tied to specific library versions used in the project

## Philosophy

> "Context is non-negotiable. LLM outputs are bounded by their context window; irrelevant or missing context literally squeezes out useful tokens."

Raw library documentation is often:
- Too verbose (50+ page tutorials)
- Too broad (covers every feature)
- Outdated (examples using old APIs)
- Missing gotchas (happy path only)

ai_docs entries are curated to include **only what's needed** for this project's use cases.

## Directory Structure

```
.claude/blueprints/ai_docs/
├── README.md                 # This file
├── libraries/                # Third-party library documentation
│   ├── pydantic-v2.md       # Pydantic patterns for this project
│   ├── fastapi.md           # FastAPI patterns for this project
│   ├── redis-py.md          # Redis client patterns
│   └── pytest.md            # Testing patterns
└── project/                  # Project-specific documentation
    ├── patterns.md          # Code patterns and conventions
    ├── conventions.md       # Naming and style conventions
    └── architecture.md      # Architecture decisions
```

## How to Curate ai_docs

### Step 1: Identify Documentation Needs

When writing a PRP, ask:
- What libraries are used?
- What are the tricky parts?
- What gotchas have we encountered?
- What patterns do we use?

### Step 2: Create Focused Entries

Each ai_docs entry should be **< 200 lines** and include:

1. **Version & Context** - What version, what project use case
2. **Quick Reference** - Common operations in one place
3. **Patterns We Use** - Project-specific patterns with code
4. **Gotchas** - Known issues with solutions
5. **Anti-Patterns** - What NOT to do

### Step 3: Link from PRPs

Reference ai_docs in PRPs:

```markdown
### ai_docs References
- See `ai_docs/libraries/redis-py.md` - Connection pooling section
- See `ai_docs/project/patterns.md` - Repository pattern
```

## Entry Template

Use this template for new ai_docs entries:

```markdown
# [Library/Topic Name]

**Version:** X.Y.Z
**Last Updated:** YYYY-MM-DD
**Use Case:** [Why we use this library in this project]

## Quick Reference

### [Common Operation 1]
```python
# Code snippet that can be directly copied
```

### [Common Operation 2]
```python
# Code snippet that can be directly copied
```

## Patterns We Use

### [Pattern Name]
[When to use this pattern]

```python
# Full example of the pattern
```

### [Another Pattern]
[When to use this pattern]

```python
# Full example of the pattern
```

## Gotchas

### Gotcha 1: [Title]
**Issue:** [What can go wrong]
**Solution:**
```python
# Correct approach
```

### Gotcha 2: [Title]
**Issue:** [What can go wrong]
**Solution:**
```python
# Correct approach
```

## Anti-Patterns

### Don't Do This
```python
# Bad example
```

### Do This Instead
```python
# Good example
```

## References

- [Official Docs - Specific Section](url)
- [GitHub Issue - Known Issue](url)
```

## Example Entry: Redis Connection Pooling

```markdown
# Redis Python Client (redis-py)

**Version:** 4.5.0+
**Last Updated:** 2024-01-15
**Use Case:** Session storage, caching, rate limiting

## Quick Reference

### Connection with Pool
```python
from redis import Redis, ConnectionPool

pool = ConnectionPool.from_url(
    "redis://localhost:6379/0",
    max_connections=50,
    socket_timeout=5,
    socket_connect_timeout=5,
)
redis = Redis(connection_pool=pool)
```

### Async Connection
```python
from redis.asyncio import Redis as AsyncRedis

redis = AsyncRedis.from_url(
    "redis://localhost:6379/0",
    encoding="utf-8",
    decode_responses=True,
)
```

### Key Operations
```python
# Set with expiry
await redis.setex("key", 3600, "value")  # 1 hour TTL

# Get with default
value = await redis.get("key") or "default"

# Atomic increment
count = await redis.incr("counter")

# Delete multiple
await redis.delete("key1", "key2", "key3")
```

## Patterns We Use

### Repository Pattern for Redis
```python
class RedisRepository:
    def __init__(self, redis: Redis, prefix: str):
        self.redis = redis
        self.prefix = prefix

    def _key(self, id: str) -> str:
        return f"{self.prefix}:{id}"

    async def get(self, id: str) -> dict | None:
        data = await self.redis.get(self._key(id))
        return json.loads(data) if data else None

    async def set(self, id: str, data: dict, ttl: int = 3600) -> None:
        await self.redis.setex(self._key(id), ttl, json.dumps(data))

    async def delete(self, id: str) -> bool:
        return await self.redis.delete(self._key(id)) > 0
```

### Atomic Operations with WATCH
```python
async def atomic_update(redis: Redis, key: str, transform: Callable) -> Any:
    async with redis.pipeline() as pipe:
        while True:
            try:
                await pipe.watch(key)
                current = await pipe.get(key)
                new_value = transform(current)
                pipe.multi()
                pipe.set(key, new_value)
                await pipe.execute()
                return new_value
            except WatchError:
                continue  # Retry on conflict
```

## Gotchas

### Gotcha 1: Connection Pool Exhaustion
**Issue:** Not using pooling causes "max connections exceeded" under load
**Solution:**
```python
# Always use connection pool in production
pool = ConnectionPool.from_url(url, max_connections=50)
redis = Redis(connection_pool=pool)
```

### Gotcha 2: Decode Responses
**Issue:** Redis returns bytes by default, causing type errors
**Solution:**
```python
# Enable decode_responses for string handling
redis = Redis.from_url(url, decode_responses=True)
```

### Gotcha 3: Pipeline vs Transaction
**Issue:** `pipeline()` is not atomic by default
**Solution:**
```python
# For atomicity, use MULTI
async with redis.pipeline() as pipe:
    pipe.multi()  # Start transaction
    pipe.set("key1", "value1")
    pipe.set("key2", "value2")
    await pipe.execute()  # Atomic execution
```

## Anti-Patterns

### Don't: Create New Connection Per Request
```python
# BAD - creates connection on every call
async def get_data(key: str):
    redis = Redis.from_url(url)  # New connection!
    return await redis.get(key)
```

### Do: Use Dependency Injection with Pool
```python
# GOOD - reuses pooled connections
async def get_data(key: str, redis: Redis = Depends(get_redis)):
    return await redis.get(key)
```

## References

- [redis-py Connection Pools](https://redis-py.readthedocs.io/en/stable/connections.html#connection-pools)
- [Redis Transactions](https://redis.io/docs/manual/transactions/)
```

## Maintenance

### When to Update ai_docs

1. **New library added** - Create entry with patterns and gotchas
2. **Gotcha discovered** - Add to relevant entry immediately
3. **Pattern evolved** - Update entry with new pattern
4. **Version upgraded** - Check for breaking changes, update entry

### Quality Checks

Before adding to ai_docs:
- [ ] Is it < 200 lines?
- [ ] Are code snippets directly usable?
- [ ] Are gotchas documented with solutions?
- [ ] Is it version-specific?
- [ ] Are anti-patterns shown?

### Using `/prp:curate-docs`

Run `/prp:curate-docs` to:
1. Research a library's documentation
2. Extract relevant patterns
3. Generate ai_docs entry
4. Review and refine

## Integration with PRPs

ai_docs are referenced in PRPs under `### ai_docs References`:

```markdown
### ai_docs References
- See `ai_docs/libraries/redis-py.md` - Connection pooling section
- See `ai_docs/project/patterns.md` - Repository pattern
```

When executing a PRP, Claude reads these references to have curated context ready.

## Benefits

1. **Consistent patterns** - Everyone uses the same code patterns
2. **Faster development** - No need to search through docs
3. **Gotcha prevention** - Known issues are documented
4. **Token efficiency** - Curated content uses fewer tokens than raw docs
5. **Team knowledge** - Tribal knowledge is explicit
