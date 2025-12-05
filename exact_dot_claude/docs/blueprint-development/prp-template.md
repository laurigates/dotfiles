# PRP Template (Product Requirement Prompt)

Use this template to create PRPs for Blueprint Development projects. PRPs extend traditional PRDs by adding AI-critical context layers that enable one-pass implementation success.

## What is a PRP?

A PRP is **PRD + Curated Codebase Intelligence + Implementation Blueprint + Validation Gates** - the minimum viable packet an AI agent needs to deliver production code successfully on first attempt.

### Key Distinction from PRDs

| PRD (Traditional) | PRP (AI-Native) |
|-------------------|-----------------|
| Specifies **what** and **why** | Also specifies **how** with implementation context |
| Avoids implementation details | Includes precise file paths, code snippets, patterns |
| Assumes human domain knowledge | Provides curated library documentation |
| Success = checkboxes | Success = executable validation commands |

### Core Principle

> "Context is non-negotiable. LLM outputs are bounded by their context window; irrelevant or missing context literally squeezes out useful tokens."

## Template

```markdown
# PRP: [Feature/Component Name]

## Goal & Why

**Goal:** [One sentence describing what needs to be accomplished]

**Business Justification:** [Why this feature/component is needed]

**Target Users:** [Who will use this feature]

**Priority:** Critical / High / Medium / Low

## Success Criteria

### Acceptance Criteria
- [ ] [Specific, testable criterion 1]
- [ ] [Specific, testable criterion 2]
- [ ] [Specific, testable criterion 3]

### Performance Baselines
- [Metric 1]: [Target value]
- [Metric 2]: [Target value]

### Security Requirements
- [ ] [Security requirement 1]
- [ ] [Security requirement 2]

## Context

### Documentation References
[URLs to external documentation with specific sections]

- [Library X - Authentication Section](url) - Required for understanding token handling
- [Framework Y - Middleware Guide](url) - Pattern for request validation
- [API Specification](url) - Endpoint contract

### ai_docs References
[Links to curated documentation in .claude/blueprints/ai_docs/]

- See `ai_docs/libraries/[library].md` - [Specific section]
- See `ai_docs/project/patterns.md` - [Specific pattern]

### Codebase Intelligence
[Precise file paths, code snippets, and patterns from the existing codebase]

**Relevant Files:**
- `src/path/to/file1.py` - [What it does, why it's relevant]
- `src/path/to/file2.py` - [What it does, why it's relevant]
- `tests/path/to/tests.py` - [Existing test patterns to follow]

**Existing Patterns:**
```python
# src/path/to/existing.py (lines 45-60)
# Pattern to follow for [X]
class ExistingService:
    def __init__(self, repository: Repository):
        self.repository = repository

    def process(self, data: InputModel) -> OutputModel:
        # Validation
        validated = self._validate(data)
        # Processing
        result = self.repository.save(validated)
        return OutputModel.from_entity(result)
```

**Integration Points:**
- [Component A] at `src/path/` - [How to integrate]
- [Component B] at `src/other/` - [How to integrate]

### Known Gotchas
[Critical implementation warnings and edge cases]

- **Gotcha 1: [Title]**
  - **Issue:** [What can go wrong]
  - **Mitigation:** [How to avoid it]
  - **Example:** [Code showing the correct approach]

- **Gotcha 2: [Title]**
  - **Issue:** [What can go wrong]
  - **Mitigation:** [How to avoid it]

- **Gotcha 3: [Library-specific warning]**
  - **Issue:** [Version-specific behavior, breaking changes, etc.]
  - **Mitigation:** [Correct usage pattern]

### Dependencies

**Libraries:**
- `library-name==X.Y.Z` - [Why this version, what it's used for]
- `other-library>=A.B.C` - [Why this version, what it's used for]

**Environment Variables:**
- `ENV_VAR_NAME` - [What it configures, example value]
- `API_KEY` - [What service it authenticates]

**External Services:**
- [Service Name] - [How it's used, endpoints involved]

## Implementation Blueprint

### Architecture Decision
**Decision:** [Architectural approach]
**Rationale:** [Why this approach was chosen]
**Alternatives Considered:** [Other options and why they were rejected]
**Trade-offs:** [What we're sacrificing for this choice]

### Task Breakdown

**Task 1: [Task Title]**
- **What:** [Specific deliverable]
- **Files:** `src/path/to/file.py`, `tests/path/to/test.py`
- **Pseudocode:**
  ```python
  # 1. Create input validation
  def validate_input(data: RawInput) -> ValidatedInput:
      # Check required fields
      # Validate format
      # Return validated or raise ValidationError

  # 2. Implement core logic
  def process(validated: ValidatedInput) -> Result:
      # Transform data
      # Apply business rules
      # Return result
  ```

**Task 2: [Task Title]**
- **What:** [Specific deliverable]
- **Files:** [Files involved]
- **Pseudocode:**
  ```python
  # Pseudocode for task 2
  ```

**Task 3: [Task Title]**
- **What:** [Specific deliverable]
- **Files:** [Files involved]
- **Pseudocode:**
  ```python
  # Pseudocode for task 3
  ```

### Implementation Order
1. [Task X] - Foundation, no dependencies
2. [Task Y] - Depends on Task X
3. [Task Z] - Depends on Task Y

## TDD Requirements

### Test Strategy

**Unit Tests:**
- [Component 1] - [What to test]
- [Component 2] - [What to test]

**Integration Tests:**
- [Integration point 1] - [What to test]
- [Integration point 2] - [What to test]

### Critical Test Cases

**Test Case 1: [Description]**
```python
def test_[feature]_[scenario]():
    # Arrange
    input_data = {...}
    expected = {...}

    # Act
    result = feature_function(input_data)

    # Assert
    assert result == expected
```

**Test Case 2: [Description]**
```python
def test_[feature]_[error_scenario]():
    # Arrange
    invalid_input = {...}

    # Act & Assert
    with pytest.raises(ExpectedError):
        feature_function(invalid_input)
```

**Test Case 3: [Edge Case]**
```python
def test_[feature]_[edge_case]():
    # Test implementation
```

## Validation Gates

[Executable commands the AI can run to verify implementation quality]

### Gate 1: Syntax & Linting
```bash
ruff check src/path/to/new/code/
ruff format --check src/path/to/new/code/
```
**Expected:** No errors, no warnings

### Gate 2: Type Checking
```bash
mypy src/path/to/new/code/ --strict
```
**Expected:** No type errors

### Gate 3: Unit Tests
```bash
pytest tests/unit/test_feature.py -v --tb=short
```
**Expected:** All tests pass

### Gate 4: Integration Tests
```bash
pytest tests/integration/test_feature.py -v --tb=short
```
**Expected:** All tests pass

### Gate 5: Coverage Check
```bash
pytest tests/ --cov=src/path/to/new/code/ --cov-fail-under=80
```
**Expected:** Coverage >= 80%

### Gate 6: Security Scan (if applicable)
```bash
bandit -r src/path/to/new/code/
```
**Expected:** No high/critical issues

## Confidence Score

Rate the completeness of this PRP (1-10 for each dimension):

| Dimension | Score | Notes |
|-----------|-------|-------|
| Context Completeness | X/10 | [All file paths, code snippets, library versions explicit?] |
| Implementation Clarity | X/10 | [Pseudocode covers all cases, step-by-step clear?] |
| Gotchas Documented | X/10 | [Known pitfalls documented with mitigations?] |
| Validation Coverage | X/10 | [Executable commands for all quality gates?] |
| **Overall** | **X/10** | [Average score] |

**Target Scores:**
- **7+**: Ready for execution
- **9+**: Ready for subagent delegation (isolated execution)

**If score < 7:**
- [ ] Add missing context to ai_docs/
- [ ] Research gotchas for libraries used
- [ ] Add more validation gates
- [ ] Clarify implementation pseudocode

## Constraints

### Technical Constraints
- [Constraint 1]: [Description and impact]
- [Constraint 2]: [Description and impact]

### Out of Scope
- [Out of scope item 1]
- [Out of scope item 2]

## Open Questions

- **Q1**: [Question needing resolution]
  - **Status**: Open / Resolved
  - **Decision**: [If resolved]

## Changelog

### [Date] - v1.0
- Initial PRP created
- Confidence score: X/10
```

## Example PRP

Here's a concrete example following the template:

```markdown
# PRP: User Session Management

## Goal & Why

**Goal:** Implement Redis-backed session management with automatic expiry and refresh token rotation.

**Business Justification:** Current in-memory sessions don't persist across server restarts, causing user logouts during deployments.

**Target Users:** All authenticated application users

**Priority:** High

## Success Criteria

### Acceptance Criteria
- [ ] Sessions persist across server restarts
- [ ] Sessions expire after 30 minutes of inactivity
- [ ] Refresh tokens rotate on each use (prevent replay attacks)
- [ ] Session data is encrypted at rest

### Performance Baselines
- Session creation: < 5ms
- Session lookup: < 2ms
- Redis memory per session: < 1KB

### Security Requirements
- [ ] Session data encrypted with AES-256-GCM
- [ ] Refresh token rotation prevents replay attacks
- [ ] Session hijacking mitigated via IP/User-Agent binding

## Context

### Documentation References

- [Redis Python Client - Connection Pooling](https://redis-py.readthedocs.io/en/stable/connections.html#connection-pools) - Required for production setup
- [Python cryptography - Fernet](https://cryptography.io/en/latest/fernet/) - Session encryption pattern
- [OWASP Session Management](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html) - Security requirements

### ai_docs References

- See `ai_docs/libraries/redis-py.md` - Connection pooling section
- See `ai_docs/project/patterns.md` - Repository pattern for data access

### Codebase Intelligence

**Relevant Files:**
- `src/auth/token_service.py` - Existing JWT generation (extend for refresh tokens)
- `src/core/config.py` - Configuration pattern to follow
- `src/core/dependencies.py` - Dependency injection pattern
- `tests/unit/auth/test_token_service.py` - Existing test patterns

**Existing Patterns:**
```python
# src/core/config.py (lines 15-25)
# Configuration pattern to follow
class Settings(BaseSettings):
    redis_url: str = "redis://localhost:6379"
    session_ttl_seconds: int = 1800  # 30 minutes

    class Config:
        env_file = ".env"

settings = Settings()
```

```python
# src/core/dependencies.py (lines 40-50)
# Dependency injection pattern
def get_redis() -> Redis:
    return Redis.from_url(
        settings.redis_url,
        encoding="utf-8",
        decode_responses=True
    )
```

**Integration Points:**
- `src/auth/router.py` at `/login` - Add session creation after JWT generation
- `src/middleware/auth.py` - Add session validation to auth middleware

### Known Gotchas

- **Gotcha 1: Redis Connection Pool Exhaustion**
  - **Issue:** Not using connection pooling causes "max connections exceeded" under load
  - **Mitigation:** Use `ConnectionPool` with explicit `max_connections` limit
  - **Example:**
    ```python
    pool = ConnectionPool.from_url(
        redis_url,
        max_connections=50,
        socket_timeout=5
    )
    redis = Redis(connection_pool=pool)
    ```

- **Gotcha 2: Fernet Token Size**
  - **Issue:** Fernet encryption adds ~50% overhead to session data
  - **Mitigation:** Compress session data before encryption if > 500 bytes

- **Gotcha 3: Redis WATCH for Token Rotation**
  - **Issue:** Concurrent refresh requests can cause race conditions
  - **Mitigation:** Use Redis transactions with WATCH/MULTI/EXEC
  - **Example:**
    ```python
    with redis.pipeline() as pipe:
        while True:
            try:
                pipe.watch(f"refresh:{old_token}")
                pipe.multi()
                pipe.delete(f"refresh:{old_token}")
                pipe.setex(f"refresh:{new_token}", ttl, user_id)
                pipe.execute()
                break
            except WatchError:
                continue  # Retry on conflict
    ```

### Dependencies

**Libraries:**
- `redis>=4.5.0` - Async support, connection pooling
- `cryptography>=41.0.0` - Fernet encryption (no known vulnerabilities)

**Environment Variables:**
- `REDIS_URL` - Redis connection string (e.g., `redis://localhost:6379/0`)
- `SESSION_ENCRYPTION_KEY` - 32-byte base64-encoded Fernet key

**External Services:**
- Redis 7.x - Session storage (must be running)

## Implementation Blueprint

### Architecture Decision
**Decision:** Use repository pattern with Redis backend, encryption layer as decorator
**Rationale:** Separates storage concerns from business logic, encryption is transparent
**Alternatives Considered:**
- Direct Redis calls (rejected: hard to test, no abstraction)
- SQLAlchemy sessions (rejected: too slow for session management)
**Trade-offs:** Slight complexity increase, but better testability and flexibility

### Task Breakdown

**Task 1: Session Repository**
- **What:** Create `SessionRepository` with CRUD operations
- **Files:** `src/auth/session_repository.py`, `tests/unit/auth/test_session_repository.py`
- **Pseudocode:**
  ```python
  class SessionRepository:
      def __init__(self, redis: Redis, encryptor: Encryptor):
          self.redis = redis
          self.encryptor = encryptor

      async def create(self, user_id: str, data: dict) -> Session:
          session_id = generate_session_id()
          encrypted = self.encryptor.encrypt(json.dumps(data))
          await self.redis.setex(
              f"session:{session_id}",
              ttl=SESSION_TTL,
              value=encrypted
          )
          return Session(id=session_id, user_id=user_id, data=data)

      async def get(self, session_id: str) -> Session | None:
          encrypted = await self.redis.get(f"session:{session_id}")
          if not encrypted:
              return None
          data = json.loads(self.encryptor.decrypt(encrypted))
          return Session.from_dict(data)

      async def refresh(self, session_id: str) -> bool:
          # Reset TTL without modifying data
          return await self.redis.expire(f"session:{session_id}", SESSION_TTL)

      async def delete(self, session_id: str) -> bool:
          return await self.redis.delete(f"session:{session_id}") > 0
  ```

**Task 2: Refresh Token Rotation**
- **What:** Implement atomic refresh token rotation with Redis transactions
- **Files:** `src/auth/token_service.py`, `tests/unit/auth/test_token_rotation.py`
- **Pseudocode:**
  ```python
  async def rotate_refresh_token(self, old_token: str) -> str | None:
      user_id = await self.redis.get(f"refresh:{old_token}")
      if not user_id:
          return None  # Token invalid or expired

      new_token = generate_refresh_token()

      # Atomic rotation with WATCH
      async with self.redis.pipeline() as pipe:
          while True:
              try:
                  await pipe.watch(f"refresh:{old_token}")
                  pipe.multi()
                  pipe.delete(f"refresh:{old_token}")
                  pipe.setex(f"refresh:{new_token}", REFRESH_TTL, user_id)
                  await pipe.execute()
                  return new_token
              except WatchError:
                  continue
  ```

**Task 3: Auth Middleware Integration**
- **What:** Add session validation to existing auth middleware
- **Files:** `src/middleware/auth.py`
- **Pseudocode:**
  ```python
  async def validate_session(request: Request) -> Session:
      session_id = request.cookies.get("session_id")
      if not session_id:
          raise HTTPException(401, "No session")

      session = await session_repo.get(session_id)
      if not session:
          raise HTTPException(401, "Session expired")

      # Refresh session TTL on activity
      await session_repo.refresh(session_id)

      return session
  ```

### Implementation Order
1. Task 1: SessionRepository - Foundation, no dependencies
2. Task 2: Refresh Token Rotation - Depends on Redis patterns from Task 1
3. Task 3: Middleware Integration - Depends on SessionRepository

## TDD Requirements

### Test Strategy

**Unit Tests:**
- `SessionRepository` - CRUD operations with mocked Redis
- `Encryptor` - Encryption/decryption roundtrip
- `RefreshTokenRotation` - Atomic rotation, race condition handling

**Integration Tests:**
- Full session lifecycle with real Redis (test container)
- Concurrent refresh token rotation (race condition test)

### Critical Test Cases

**Test Case 1: Session Creation**
```python
async def test_session_create_stores_encrypted_data():
    # Arrange
    user_id = "user-123"
    session_data = {"role": "admin", "preferences": {"theme": "dark"}}

    # Act
    session = await repo.create(user_id, session_data)

    # Assert
    assert session.id is not None
    assert session.user_id == user_id

    # Verify encryption (raw Redis value should not be readable JSON)
    raw = await redis.get(f"session:{session.id}")
    with pytest.raises(json.JSONDecodeError):
        json.loads(raw)
```

**Test Case 2: Refresh Token Rotation Atomicity**
```python
async def test_refresh_token_rotation_is_atomic():
    # Arrange
    old_token = "old-token-123"
    await redis.setex(f"refresh:{old_token}", 3600, "user-123")

    # Act
    new_token = await token_service.rotate_refresh_token(old_token)

    # Assert
    assert new_token is not None
    assert await redis.get(f"refresh:{old_token}") is None  # Old deleted
    assert await redis.get(f"refresh:{new_token}") == "user-123"  # New exists
```

**Test Case 3: Expired Session Returns None**
```python
async def test_get_expired_session_returns_none():
    # Arrange
    session = await repo.create("user-123", {"data": "test"})
    await redis.delete(f"session:{session.id}")  # Simulate expiry

    # Act
    result = await repo.get(session.id)

    # Assert
    assert result is None
```

## Validation Gates

### Gate 1: Syntax & Linting
```bash
ruff check src/auth/session_repository.py src/auth/token_service.py
ruff format --check src/auth/
```
**Expected:** No errors, no warnings

### Gate 2: Type Checking
```bash
mypy src/auth/session_repository.py src/auth/token_service.py --strict
```
**Expected:** No type errors

### Gate 3: Unit Tests
```bash
pytest tests/unit/auth/test_session_repository.py tests/unit/auth/test_token_rotation.py -v
```
**Expected:** All tests pass

### Gate 4: Integration Tests
```bash
pytest tests/integration/auth/test_session_lifecycle.py -v --tb=short
```
**Expected:** All tests pass

### Gate 5: Coverage Check
```bash
pytest tests/ --cov=src/auth/session_repository --cov=src/auth/token_service --cov-fail-under=90
```
**Expected:** Coverage >= 90%

### Gate 6: Security Scan
```bash
bandit -r src/auth/session_repository.py src/auth/token_service.py
```
**Expected:** No high/critical issues

## Confidence Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Context Completeness | 9/10 | All file paths explicit, code patterns provided |
| Implementation Clarity | 9/10 | Pseudocode covers main paths, edge cases documented |
| Gotchas Documented | 8/10 | Major gotchas covered, may discover more during implementation |
| Validation Coverage | 9/10 | All quality gates have executable commands |
| **Overall** | **8.75/10** | Ready for subagent delegation |

## Constraints

### Technical Constraints
- Must use existing Redis instance (no new infrastructure)
- Session encryption key must be rotatable without invalidating sessions

### Out of Scope
- Multi-region session replication
- Session analytics/auditing
- Admin session management UI

## Changelog

### 2024-01-15 - v1.0
- Initial PRP created
- Confidence score: 8.75/10
```

## PRP Best Practices

### Context Density

**Goal:** Maximum useful information per token

**DO:**
```markdown
### Existing Pattern
```python
# src/auth/service.py:45-52 (EXACT location)
async def validate_token(token: str) -> User | None:
    try:
        payload = jwt.decode(token, SECRET, algorithms=["RS256"])
        return await self.user_repo.get(payload["sub"])
    except JWTError:
        return None
```
```

**DON'T:**
```markdown
### Existing Pattern
There's some token validation code somewhere in the auth module.
```

### Known Gotchas

**Every PRP should document:**
1. Library-specific edge cases
2. Version-specific behaviors
3. Common mistakes in this codebase
4. Race conditions and concurrency issues
5. Performance pitfalls

### Validation Gates

**Every PRP must have executable commands for:**
1. Linting/formatting
2. Type checking (if applicable)
3. Unit tests
4. Integration tests (if applicable)
5. Coverage check
6. Security scan (if applicable)

### Confidence Scoring

**Score honestly:**
- If you're uncertain about gotchas → lower score
- If pseudocode has gaps → lower score
- If validation commands are incomplete → lower score

**A low score is not failure** - it indicates where to invest more research before execution.

## Integration with Blueprint Development

PRPs serve as the enhanced input for the Blueprint Development workflow:

```
PRPs (enhanced context) → Skills (patterns) → Work-Orders (tasks) → Subagent Execution
```

**From PRP, generate:**
- **Architecture Skills** from `Implementation Blueprint`
- **Testing Skills** from `TDD Requirements`
- **Quality Skills** from `Validation Gates` and `Success Criteria`
- **Work-Orders** from `Task Breakdown`

**PRP Confidence Score determines:**
- **7+**: Execute with `/prp:execute`
- **9+**: Delegate to subagent with work-order
- **< 7**: Invest in research and documentation first
