# Project Conventions

**Last Updated:** YYYY-MM-DD

This document describes naming conventions, code style, and structural conventions for this project.

## Naming Conventions

### Files & Directories

| Type | Convention | Example |
|------|------------|---------|
| Python modules | `snake_case` | `user_service.py` |
| Test files | `test_<module>.py` | `test_user_service.py` |
| Configuration | `snake_case` | `database_config.py` |
| Constants | `SCREAMING_SNAKE_CASE` | `MAX_RETRIES` |

### Classes

| Type | Convention | Example |
|------|------------|---------|
| Domain models | `PascalCase` | `User`, `Order` |
| Services | `PascalCase` + `Service` | `UserService` |
| Repositories | `PascalCase` + `Repository` | `UserRepository` |
| Exceptions | `PascalCase` + `Error` | `NotFoundError` |
| Schemas | `PascalCase` + purpose | `CreateUserRequest`, `UserResponse` |

### Functions & Methods

| Type | Convention | Example |
|------|------------|---------|
| Public functions | `snake_case` | `get_user()` |
| Private functions | `_snake_case` | `_validate_email()` |
| Async functions | `snake_case` | `async def fetch_user()` |
| Boolean returns | `is_/has_/can_` prefix | `is_valid()`, `has_permission()` |

### Variables

| Type | Convention | Example |
|------|------------|---------|
| Local variables | `snake_case` | `user_id` |
| Constants | `SCREAMING_SNAKE_CASE` | `DEFAULT_TIMEOUT` |
| Private attributes | `_snake_case` | `self._cache` |
| Type variables | `PascalCase` + `T` | `UserT`, `ResponseT` |

## Code Style

### Imports

Order imports as follows:
1. Standard library
2. Third-party packages
3. Local imports

```python
# Standard library
import json
from datetime import datetime
from typing import TYPE_CHECKING

# Third-party
from fastapi import APIRouter, Depends
from pydantic import BaseModel

# Local
from src.core.config import settings
from src.domain.models import User
```

### Type Hints

Always use type hints:

```python
# Functions
def get_user(user_id: str) -> User | None:
    pass

# Async functions
async def fetch_users(limit: int = 10) -> list[User]:
    pass

# Class attributes
class UserService:
    def __init__(self, repo: UserRepository) -> None:
        self.repo: UserRepository = repo
```

### Docstrings

Use Google-style docstrings for public APIs:

```python
def create_user(email: str, name: str) -> User:
    """Create a new user account.

    Args:
        email: User's email address (must be unique).
        name: User's display name.

    Returns:
        The newly created User object.

    Raises:
        ValidationError: If email format is invalid.
        ConflictError: If email already exists.

    Example:
        >>> user = create_user("test@example.com", "Test User")
        >>> print(user.id)
        'usr_abc123'
    """
```

### Comments

- Use comments to explain **why**, not **what**
- Keep comments up to date with code changes
- Prefer self-documenting code over comments

```python
# BAD - explains what (obvious from code)
# Increment counter by 1
counter += 1

# GOOD - explains why
# Rate limit window resets after each successful request
counter += 1
```

## Structural Conventions

### Module Size

- **Max lines per file:** 300 (split if larger)
- **Max lines per function:** 30 (extract helpers)
- **Max lines per class:** 200 (extract base classes)

### Function Signatures

- **Max parameters:** 5 (use dataclass/Pydantic if more)
- **Use keyword-only for optional params:** `*, flag: bool = False`

```python
# BAD - too many positional params
def create_user(email, name, age, role, active, verified):
    pass

# GOOD - use a request object
def create_user(request: CreateUserRequest) -> User:
    pass

# GOOD - keyword-only for options
def search_users(
    query: str,
    *,
    limit: int = 10,
    include_inactive: bool = False,
) -> list[User]:
    pass
```

### Error Handling

- Use custom exceptions, not generic ones
- Include context in error messages
- Don't catch exceptions you can't handle

```python
# BAD
try:
    user = get_user(user_id)
except Exception:
    return None

# GOOD
try:
    user = await self.repo.get(user_id)
except DatabaseError as e:
    logger.error(f"Failed to fetch user {user_id}: {e}")
    raise ServiceUnavailableError("Database unavailable") from e

if not user:
    raise NotFoundError(f"User {user_id} not found")
```

### Return Early

Prefer early returns over nested conditionals:

```python
# BAD - deeply nested
def process_user(user: User | None) -> Result:
    if user:
        if user.is_active:
            if user.has_permission("write"):
                return do_thing(user)
            else:
                return Error("No permission")
        else:
            return Error("Inactive")
    else:
        return Error("No user")

# GOOD - early returns
def process_user(user: User | None) -> Result:
    if not user:
        return Error("No user")

    if not user.is_active:
        return Error("Inactive")

    if not user.has_permission("write"):
        return Error("No permission")

    return do_thing(user)
```

## Testing Conventions

### Test File Location

Tests are colocated with source:
```
src/domain/services/user_service.py
tests/unit/domain/services/test_user_service.py
tests/integration/domain/services/test_user_service.py
```

### Test Naming

```python
def test_<method>_<scenario>_<expected_outcome>():
    pass

# Examples
def test_create_user_with_valid_data_returns_user():
    pass

def test_create_user_with_duplicate_email_raises_conflict_error():
    pass

def test_get_user_when_not_found_returns_none():
    pass
```

### Test Structure (AAA)

Always use Arrange-Act-Assert:

```python
def test_user_creation():
    # Arrange
    request = CreateUserRequest(email="test@example.com", name="Test")
    repo = Mock(spec=UserRepository)
    repo.get_by_email.return_value = None
    service = UserService(repo)

    # Act
    result = service.create_user(request)

    # Assert
    assert result.email == "test@example.com"
    repo.save.assert_called_once()
```

## Git Conventions

### Commit Messages

Use conventional commits:

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code refactoring
- `test`: Adding/updating tests
- `docs`: Documentation changes
- `chore`: Maintenance tasks

Examples:
```
feat(auth): add refresh token rotation

Implements automatic refresh token rotation on each use
to prevent replay attacks.

Refs: #123
```

### Branch Naming

```
<type>/<ticket-id>-<short-description>
```

Examples:
- `feat/AUTH-123-refresh-token-rotation`
- `fix/BUG-456-session-expiry`
- `refactor/TECH-789-simplify-user-service`

## Logging Conventions

### Log Levels

| Level | Usage |
|-------|-------|
| `DEBUG` | Detailed diagnostic info |
| `INFO` | Normal operation events |
| `WARNING` | Unexpected but handled situations |
| `ERROR` | Errors that prevent operation completion |
| `CRITICAL` | System-wide failures |

### Log Format

Include context in structured logs:

```python
import structlog

logger = structlog.get_logger()

# Include relevant context
logger.info(
    "user_created",
    user_id=user.id,
    email=user.email,
    source="api",
)

# Include error context
logger.error(
    "user_creation_failed",
    email=request.email,
    error=str(e),
    error_type=type(e).__name__,
)
```
