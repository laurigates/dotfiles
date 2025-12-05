# Project Patterns

**Last Updated:** YYYY-MM-DD

This document describes the code patterns and conventions used in this project.

## Architecture Overview

```
src/
├── core/                 # Core infrastructure
│   ├── config.py        # Configuration management
│   ├── dependencies.py  # Dependency injection
│   └── exceptions.py    # Custom exceptions
├── domain/              # Business logic
│   ├── models/          # Domain models
│   ├── services/        # Business services
│   └── repositories/    # Data access
├── api/                 # API layer
│   ├── routes/          # Route handlers
│   ├── schemas/         # Request/Response schemas
│   └── middleware/      # HTTP middleware
└── infrastructure/      # External integrations
    ├── database/        # Database clients
    ├── cache/           # Cache clients
    └── external/        # Third-party APIs
```

## Core Patterns

### Configuration Pattern

All configuration uses Pydantic Settings:

```python
# src/core/config.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Database
    database_url: str
    database_pool_size: int = 10

    # Redis
    redis_url: str = "redis://localhost:6379"

    # Feature flags
    enable_feature_x: bool = False

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()
```

**Usage:**
```python
from src.core.config import settings

connection = create_connection(settings.database_url)
```

### Dependency Injection Pattern

Use FastAPI's dependency injection:

```python
# src/core/dependencies.py
from functools import lru_cache
from typing import Annotated
from fastapi import Depends

@lru_cache
def get_settings() -> Settings:
    return Settings()

def get_database(
    settings: Annotated[Settings, Depends(get_settings)]
) -> Database:
    return Database(settings.database_url)

def get_user_service(
    db: Annotated[Database, Depends(get_database)]
) -> UserService:
    return UserService(db)
```

**Usage in routes:**
```python
@router.get("/users/{user_id}")
async def get_user(
    user_id: str,
    service: Annotated[UserService, Depends(get_user_service)]
) -> UserResponse:
    return await service.get(user_id)
```

### Repository Pattern

Data access through repository interfaces:

```python
# src/domain/repositories/user_repository.py
from abc import ABC, abstractmethod

class UserRepository(ABC):
    @abstractmethod
    async def get(self, user_id: str) -> User | None:
        pass

    @abstractmethod
    async def save(self, user: User) -> User:
        pass

    @abstractmethod
    async def delete(self, user_id: str) -> bool:
        pass

# src/infrastructure/database/postgres_user_repository.py
class PostgresUserRepository(UserRepository):
    def __init__(self, db: Database):
        self.db = db

    async def get(self, user_id: str) -> User | None:
        row = await self.db.fetchone(
            "SELECT * FROM users WHERE id = $1",
            user_id
        )
        return User.from_row(row) if row else None

    async def save(self, user: User) -> User:
        await self.db.execute(
            "INSERT INTO users (id, email, name) VALUES ($1, $2, $3)",
            user.id, user.email, user.name
        )
        return user

    async def delete(self, user_id: str) -> bool:
        result = await self.db.execute(
            "DELETE FROM users WHERE id = $1",
            user_id
        )
        return result.rowcount > 0
```

### Service Pattern

Business logic in service classes:

```python
# src/domain/services/user_service.py
class UserService:
    def __init__(
        self,
        user_repo: UserRepository,
        email_service: EmailService,
    ):
        self.user_repo = user_repo
        self.email_service = email_service

    async def create_user(self, data: CreateUserRequest) -> User:
        # Validation
        if await self.user_repo.get_by_email(data.email):
            raise UserAlreadyExistsError(data.email)

        # Create user
        user = User(
            id=generate_id(),
            email=data.email,
            name=data.name,
        )
        await self.user_repo.save(user)

        # Side effects
        await self.email_service.send_welcome(user.email)

        return user
```

### Error Handling Pattern

Custom exceptions with error codes:

```python
# src/core/exceptions.py
class AppError(Exception):
    """Base application error"""
    status_code: int = 500
    error_code: str = "INTERNAL_ERROR"

    def __init__(self, message: str, details: dict | None = None):
        self.message = message
        self.details = details or {}
        super().__init__(message)

class NotFoundError(AppError):
    status_code = 404
    error_code = "NOT_FOUND"

class ValidationError(AppError):
    status_code = 400
    error_code = "VALIDATION_ERROR"

class ConflictError(AppError):
    status_code = 409
    error_code = "CONFLICT"

# Usage
raise NotFoundError(f"User {user_id} not found")
raise ValidationError("Invalid email format", {"field": "email"})
```

**Global error handler:**
```python
# src/api/middleware/error_handler.py
@app.exception_handler(AppError)
async def app_error_handler(request: Request, exc: AppError):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": exc.error_code,
            "message": exc.message,
            "details": exc.details,
        }
    )
```

## API Patterns

### Request/Response Schemas

Use Pydantic for all API schemas:

```python
# src/api/schemas/user.py
from pydantic import BaseModel, EmailStr, Field

class CreateUserRequest(BaseModel):
    email: EmailStr
    name: str = Field(..., min_length=1, max_length=100)

class UserResponse(BaseModel):
    id: str
    email: str
    name: str
    created_at: datetime

    class Config:
        from_attributes = True  # Pydantic v2
```

### Route Handler Pattern

Keep route handlers thin:

```python
# src/api/routes/users.py
from fastapi import APIRouter, Depends, status
from typing import Annotated

router = APIRouter(prefix="/users", tags=["users"])

@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_user(
    request: CreateUserRequest,
    service: Annotated[UserService, Depends(get_user_service)],
) -> UserResponse:
    user = await service.create_user(request)
    return UserResponse.from_orm(user)

@router.get("/{user_id}")
async def get_user(
    user_id: str,
    service: Annotated[UserService, Depends(get_user_service)],
) -> UserResponse:
    user = await service.get(user_id)
    if not user:
        raise NotFoundError(f"User {user_id} not found")
    return UserResponse.from_orm(user)
```

## Testing Patterns

### Unit Test Structure

```python
# tests/unit/domain/services/test_user_service.py
import pytest
from unittest.mock import AsyncMock, Mock

class TestUserService:
    @pytest.fixture
    def user_repo(self):
        return AsyncMock(spec=UserRepository)

    @pytest.fixture
    def email_service(self):
        return AsyncMock(spec=EmailService)

    @pytest.fixture
    def service(self, user_repo, email_service):
        return UserService(user_repo, email_service)

    async def test_create_user_success(self, service, user_repo):
        # Arrange
        user_repo.get_by_email.return_value = None
        request = CreateUserRequest(email="test@example.com", name="Test")

        # Act
        user = await service.create_user(request)

        # Assert
        assert user.email == "test@example.com"
        user_repo.save.assert_called_once()

    async def test_create_user_duplicate_email_raises(self, service, user_repo):
        # Arrange
        user_repo.get_by_email.return_value = existing_user
        request = CreateUserRequest(email="exists@example.com", name="Test")

        # Act & Assert
        with pytest.raises(UserAlreadyExistsError):
            await service.create_user(request)
```

### Integration Test Structure

```python
# tests/integration/api/test_users.py
import pytest
from httpx import AsyncClient

@pytest.fixture
async def client(app):
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client

class TestUsersAPI:
    async def test_create_user(self, client):
        # Act
        response = await client.post("/users/", json={
            "email": "test@example.com",
            "name": "Test User"
        })

        # Assert
        assert response.status_code == 201
        data = response.json()
        assert data["email"] == "test@example.com"

    async def test_get_nonexistent_user_returns_404(self, client):
        # Act
        response = await client.get("/users/nonexistent-id")

        # Assert
        assert response.status_code == 404
        assert response.json()["error"] == "NOT_FOUND"
```

## Common Gotchas

### Circular Import Prevention

**Issue:** Circular imports between modules

**Solution:** Import at function level or use TYPE_CHECKING:
```python
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from src.domain.services import UserService

def create_user_service() -> "UserService":
    from src.domain.services import UserService
    return UserService(...)
```

### Async Context Managers

**Issue:** Not properly cleaning up async resources

**Solution:** Always use async context managers:
```python
# BAD
db = await Database.connect(url)
# ... code that might fail
await db.disconnect()  # Might not run!

# GOOD
async with Database.connect(url) as db:
    # ... code
# Cleanup guaranteed
```

### Dependency Lifecycle

**Issue:** Creating expensive resources on every request

**Solution:** Use `@lru_cache` or lifespan events:
```python
# For singletons
@lru_cache
def get_settings() -> Settings:
    return Settings()

# For async resources
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    app.state.db = await Database.connect(settings.database_url)
    yield
    # Shutdown
    await app.state.db.disconnect()
```
