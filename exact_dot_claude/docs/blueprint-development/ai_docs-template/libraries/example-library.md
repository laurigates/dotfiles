# [Library Name]

**Version:** X.Y.Z
**Last Updated:** YYYY-MM-DD
**Use Case:** [Why we use this library in this project]

## Quick Reference

### Installation
```bash
pip install library-name==X.Y.Z
# or
uv add library-name==X.Y.Z
```

### Basic Usage
```python
from library import Thing

# Most common operation
thing = Thing(config="value")
result = thing.do_something()
```

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

**When to use:** [Describe the situation]

```python
# Full example of the pattern as used in this project
class OurImplementation:
    def __init__(self, library_thing: Thing):
        self.thing = library_thing

    def our_method(self) -> Result:
        # How we use the library
        return self.thing.do_something()
```

### [Another Pattern]

**When to use:** [Describe the situation]

```python
# Full example
```

## Configuration

### Environment Variables
```bash
LIBRARY_API_KEY=your-key-here
LIBRARY_TIMEOUT=30
```

### Our Config Pattern
```python
from pydantic_settings import BaseSettings

class LibrarySettings(BaseSettings):
    api_key: str
    timeout: int = 30

    class Config:
        env_prefix = "LIBRARY_"

settings = LibrarySettings()
```

## Gotchas

### Gotcha 1: [Title]

**Issue:** [What can go wrong and when]

**Symptoms:**
- [Error message or behavior]
- [Another symptom]

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

### Gotcha 3: [Version-Specific Issue]

**Issue:** [Breaking change in version X.Y]

**Solution:**
```python
# New API
```

## Anti-Patterns

### Don't: [Bad Practice]
```python
# BAD - explanation of why
bad_example = something_wrong()
```

### Do: [Good Practice]
```python
# GOOD - explanation of why
good_example = correct_approach()
```

## Testing

### How to Mock
```python
from unittest.mock import Mock, patch

@patch("library.Thing")
def test_our_code(mock_thing):
    mock_thing.return_value.do_something.return_value = expected
    # Test code
```

### Test Fixtures
```python
import pytest

@pytest.fixture
def library_thing():
    return Thing(config="test-value")
```

## Common Errors

### Error: [Error Name]
```
ErrorMessage: Something went wrong
```
**Cause:** [Why this happens]
**Fix:** [How to fix it]

### Error: [Another Error]
```
AnotherError: Details
```
**Cause:** [Why this happens]
**Fix:** [How to fix it]

## References

- [Official Docs](url)
- [API Reference](url)
- [GitHub - Relevant Issue](url)
