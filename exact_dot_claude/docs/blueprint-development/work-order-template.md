# Work-Order Template

Use this template to create work-order documents for isolated subagent execution in Blueprint Development projects. Enhanced with PRP (Product Requirement Prompt) concepts for one-pass implementation success.

## Purpose

Work-orders are **minimal-context task packages** that enable clean subagent delegation. They contain:
- **Specific objective** - Exactly what needs to be done
- **Required context only** - Relevant files, decisions, and dependencies
- **ai_docs references** - Curated library documentation for the task
- **Known gotchas** - Critical warnings and edge cases
- **TDD requirements** - Tests to write first, then implementation
- **Validation gates** - Executable commands to verify quality
- **Confidence score** - Quality assessment for delegation readiness

## Template

```markdown
# Work-Order NNN: [Task Name]

## Objective
[One sentence describing what needs to be accomplished]

## Context

### Required Files
[List only the files that need to be created, modified, or referenced]

- `path/to/file1.js` - [What needs to be done with this file]
- `path/to/file2.js` - [What needs to be done with this file]
- `tests/path/to/test.js` - [Tests to write]

### PRP Reference
[Link to specific section of relevant PRP]

See `.claude/blueprints/prps/[prp-name].md` - [Section Name]

### ai_docs References
[Links to curated documentation relevant to this task]

- See `ai_docs/libraries/[library].md` - [Specific section]
- See `ai_docs/project/patterns.md` - [Specific pattern to follow]

### Technical Decisions
[Only the decisions relevant to this specific task]

- **Decision 1**: [Brief description] - [Why it matters for this task]
- **Decision 2**: [Brief description] - [Why it matters for this task]

### Existing Code
[Only include code that the subagent needs to understand or integrate with]

```language
// path/to/existing/file.js (relevant excerpt)
[Minimal code snippet showing what exists]
```

### Dependencies
[External libraries, services, or components this task depends on]

- **Library/Service**: [What it does, how it's used in this task]
- **Environment Variables**: [Any required configuration]

### Known Gotchas
[Critical implementation warnings specific to this task]

- **Gotcha 1: [Title]**
  - **Issue:** [What can go wrong]
  - **Mitigation:** [How to avoid it]

- **Gotcha 2: [Title]**
  - **Issue:** [What can go wrong]
  - **Mitigation:** [How to avoid it]

## TDD Requirements

### Test 1: [Test Description]
[Describe the test to write first]

```language
describe('[Feature/Function]', () => {
  it('should [expected behavior]', () => {
    // Test implementation
  });
});
```

**Expected Outcome**: Test should fail (no implementation yet)

### Test 2: [Test Description]
[Describe the second test]

```language
describe('[Feature/Function]', () => {
  it('should [expected behavior]', () => {
    // Test implementation
  });
});
```

**Expected Outcome**: Test should fail (no implementation yet)

[Add more tests as needed]

## Implementation Steps

1. **Write Test 1** - [Description]
   - Run tests: `[test command]`
   - Expected: **FAIL**

2. **Implement Test 1** - [Minimal implementation needed]
   - Run tests: `[test command]`
   - Expected: **PASS**

3. **Refactor (if needed)** - [Refactoring opportunities]
   - Run tests: `[test command]`
   - Expected: **STILL PASS**

4. **Write Test 2** - [Description]
   - Run tests: `[test command]`
   - Expected: **FAIL** (new test)

5. **Implement Test 2** - [Minimal implementation needed]
   - Run tests: `[test command]`
   - Expected: **PASS**

6. **Refactor (if needed)** - [Refactoring opportunities]
   - Run tests: `[test command]`
   - Expected: **STILL PASS**

[Repeat for all tests]

## Success Criteria

- [ ] All specified tests written and passing
- [ ] [Specific functional requirement met]
- [ ] [Specific non-functional requirement met]
- [ ] [Performance/security/quality baseline met]
- [ ] Code follows project patterns (see `.claude/skills/`)
- [ ] No regressions (all existing tests still pass)

## Validation Gates
[Executable commands to verify implementation quality]

### Gate 1: Linting
```bash
[linting command for new/modified files]
```
**Expected:** No errors

### Gate 2: Type Checking
```bash
[type checking command]
```
**Expected:** No errors

### Gate 3: Unit Tests
```bash
[test command for specific tests]
```
**Expected:** All pass

### Gate 4: Full Test Suite
```bash
[full test suite command]
```
**Expected:** No regressions

## Performance Baselines
[Only if relevant to this task]

- [Metric]: [Target value]

## Security Checklist
[Only if relevant to this task]

- [ ] [Security requirement 1]
- [ ] [Security requirement 2]

## Notes
[Any additional context or considerations not covered above]

- [Note 1]
- [Note 2]

## Confidence Score

Rate the work-order quality (1-10 for each dimension):

| Dimension | Score | Notes |
|-----------|-------|-------|
| Context Completeness | X/10 | [Are all file paths, code snippets explicit?] |
| Gotchas Documented | X/10 | [Are known pitfalls documented?] |
| Test Coverage | X/10 | [Are all test cases specified?] |
| Validation Gates | X/10 | [Are executable commands provided?] |
| **Overall** | **X/10** | [Average score] |

**Scoring Guide:**
- **9+**: Ready for isolated subagent execution
- **7-8**: Ready for execution with some discovery
- **< 7**: Needs more context/research before execution

## Related Work-Orders
[If this work-order depends on or blocks other work-orders]

- **Depends on**: Work-Order NNN - [Task name]
- **Blocks**: Work-Order NNN - [Task name]
```

## Example Work-Order

Here's a concrete example following the template:

```markdown
# Work-Order 003: Implement JWT Token Generation

## Objective
Implement JWT access token and refresh token generation methods in the authentication service.

## Context

### Required Files
- `services/authService.js` - Add `generateAccessToken()` and `generateRefreshToken()` methods
- `tests/unit/services/authService.test.js` - Add token generation tests
- `config/jwt.js` - Create JWT configuration module

### PRP Reference
See `.claude/blueprints/prps/user-authentication.md` - Section: "Token Management"

### ai_docs References
- See `ai_docs/libraries/jsonwebtoken.md` - RS256 signing section
- See `ai_docs/libraries/redis-py.md` - Key expiration patterns
- See `ai_docs/project/patterns.md` - Service layer pattern

### Technical Decisions
- **JWT Signing Algorithm**: RS256 (asymmetric) for better security
  - Public key can be shared for verification
  - Private key kept secret for signing
- **Token Expiry**: Access tokens 15min, refresh tokens 7 days
  - Short-lived access tokens limit exposure
  - Long-lived refresh tokens reduce friction
- **Refresh Token Storage**: Redis with TTL
  - Fast lookups, automatic expiration
  - Allows token revocation

### Existing Code

```javascript
// services/authService.js (relevant excerpt)
class AuthService {
  constructor(userRepository, redisClient) {
    this.userRepository = userRepository;
    this.redis = redisClient;
  }

  async register(email, password) {
    const hashedPassword = await bcrypt.hash(password, 12);
    const user = await this.userRepository.create({
      email,
      password: hashedPassword
    });
    return user.id;
  }
}
```

### Dependencies
- **jsonwebtoken** (`npm install jsonwebtoken`) - JWT generation and signing
- **uuid** (`npm install uuid`) - Generating unique refresh token IDs
- **Environment Variables**:
  - `JWT_PRIVATE_KEY` - RSA private key (PEM format)
  - `JWT_PUBLIC_KEY` - RSA public key (PEM format)
  - `ACCESS_TOKEN_EXPIRY` - Default: "15m"
  - `REFRESH_TOKEN_EXPIRY` - Default: "7d"

### Known Gotchas

- **Gotcha 1: RS256 Key Format**
  - **Issue:** `jsonwebtoken` expects PEM format, not raw key bytes
  - **Mitigation:** Ensure keys start with `-----BEGIN RSA PRIVATE KEY-----`

- **Gotcha 2: Clock Skew in Token Expiry**
  - **Issue:** Server time differences can cause premature token expiration
  - **Mitigation:** Add 30-second buffer to expiry checks; use NTP sync

- **Gotcha 3: Redis Connection Pool**
  - **Issue:** Creating new Redis connection per request exhausts connections
  - **Mitigation:** Use shared Redis client with connection pooling

## TDD Requirements

### Test 1: Generate Access Token with Valid Claims

```javascript
describe('generateAccessToken', () => {
  it('should generate JWT with userId and email claims', () => {
    const user = { id: '123e4567-e89b-12d3-a456-426614174000', email: 'test@example.com' };
    const token = authService.generateAccessToken(user);

    expect(token).toBeDefined();
    expect(typeof token).toBe('string');

    // Verify token structure (should have 3 parts separated by dots)
    const parts = token.split('.');
    expect(parts.length).toBe(3);
  });
});
```

**Expected Outcome**: Test should fail - `generateAccessToken` method doesn't exist

### Test 2: Access Token Contains Correct Claims

```javascript
describe('generateAccessToken', () => {
  it('should include userId and email in token payload', () => {
    const jwt = require('jsonwebtoken');
    const user = { id: '123e4567-e89b-12d3-a456-426614174000', email: 'test@example.com' };
    const token = authService.generateAccessToken(user);

    const decoded = jwt.verify(token, process.env.JWT_PUBLIC_KEY);

    expect(decoded.userId).toBe(user.id);
    expect(decoded.email).toBe(user.email);
    expect(decoded.iat).toBeDefined(); // Issued at
    expect(decoded.exp).toBeDefined(); // Expiry
  });
});
```

**Expected Outcome**: Test should fail initially, then pass after implementation

### Test 3: Access Token Expires After 15 Minutes

```javascript
describe('generateAccessToken', () => {
  it('should set expiry to 15 minutes from now', () => {
    const jwt = require('jsonwebtoken');
    const user = { id: '123e4567-e89b-12d3-a456-426614174000', email: 'test@example.com' };
    const token = authService.generateAccessToken(user);

    const decoded = jwt.verify(token, process.env.JWT_PUBLIC_KEY);
    const expectedExpiry = Math.floor(Date.now() / 1000) + (15 * 60); // 15 minutes

    expect(decoded.exp).toBeCloseTo(expectedExpiry, -1); // Within 10 seconds
  });
});
```

**Expected Outcome**: Test should fail initially, then pass after implementation

### Test 4: Generate Refresh Token

```javascript
describe('generateRefreshToken', () => {
  it('should generate unique refresh token and store in Redis', async () => {
    const user = { id: '123e4567-e89b-12d3-a456-426614174000' };
    const refreshToken = await authService.generateRefreshToken(user);

    expect(refreshToken).toBeDefined();
    expect(typeof refreshToken).toBe('string');
    expect(refreshToken.length).toBeGreaterThan(20); // UUID should be longish
  });
});
```

**Expected Outcome**: Test should fail - `generateRefreshToken` method doesn't exist

### Test 5: Refresh Token Stored in Redis with TTL

```javascript
describe('generateRefreshToken', () => {
  it('should store refresh token in Redis with 7-day expiry', async () => {
    const user = { id: '123e4567-e89b-12d3-a456-426614174000' };
    const refreshToken = await authService.generateRefreshToken(user);

    // Check Redis storage
    const stored = await authService.redis.get(`refresh:${refreshToken}`);
    expect(stored).toBe(user.id);

    // Check TTL (should be 7 days = 604800 seconds)
    const ttl = await authService.redis.ttl(`refresh:${refreshToken}`);
    expect(ttl).toBeGreaterThan(604790); // Allow small margin
    expect(ttl).toBeLessThanOrEqual(604800);
  });
});
```

**Expected Outcome**: Test should fail initially, then pass after implementation

## Implementation Steps

1. **Create JWT Config Module**
   - Create `config/jwt.js` to centralize JWT settings
   - Load private/public keys from environment variables
   - Export configuration object

2. **Write Test 1** - Generate access token with valid claims
   - Run tests: `npm test -- authService.test.js`
   - Expected: **FAIL** (method doesn't exist)

3. **Implement `generateAccessToken(user)`**
   - Use `jsonwebtoken.sign()` with user claims
   - Sign with private key using RS256 algorithm
   - Set expiry to 15 minutes
   - Run tests: `npm test -- authService.test.js`
   - Expected: **PASS** (Test 1)

4. **Write Tests 2 & 3** - Verify claims and expiry
   - Run tests: `npm test -- authService.test.js`
   - Expected: **FAIL** (new tests, implementation incomplete)

5. **Update `generateAccessToken()` to include all claims**
   - Ensure userId, email, iat, exp are in payload
   - Run tests: `npm test -- authService.test.js`
   - Expected: **PASS** (Tests 1, 2, 3)

6. **Refactor (if needed)**
   - Extract magic numbers to constants
   - Improve error handling
   - Run tests: `npm test -- authService.test.js`
   - Expected: **STILL PASS**

7. **Write Tests 4 & 5** - Generate and store refresh token
   - Run tests: `npm test -- authService.test.js`
   - Expected: **FAIL** (method doesn't exist)

8. **Implement `generateRefreshToken(user)`**
   - Generate unique token using UUID
   - Store in Redis with key `refresh:{token}` and value `user.id`
   - Set Redis TTL to 7 days (604800 seconds)
   - Run tests: `npm test -- authService.test.js`
   - Expected: **PASS** (Tests 4, 5)

9. **Refactor (if needed)**
   - Extract Redis key prefix to constant
   - Extract TTL to configuration
   - Run tests: `npm test -- authService.test.js`
   - Expected: **STILL PASS**

10. **Verify All Tests Pass**
    - Run full test suite: `npm test`
    - Expected: **ALL PASS** (no regressions)

## Success Criteria

- [ ] `generateAccessToken(user)` creates valid JWT with userId and email claims
- [ ] Access tokens expire after 15 minutes
- [ ] Access tokens signed with RS256 using private key
- [ ] `generateRefreshToken(user)` creates unique refresh token
- [ ] Refresh tokens stored in Redis with 7-day TTL
- [ ] All tests pass (5 new unit tests)
- [ ] No existing tests broken (regression check)
- [ ] Token generation performance < 10ms (per PRD baseline)

## Performance Baselines

- **Token generation time**: < 10ms per token
  - Measure with `console.time()` in tests
  - RS256 signing should be fast for single tokens

## Security Checklist

- [ ] Private key never logged or exposed in code
- [ ] Private key loaded from environment variable only
- [ ] Refresh tokens use cryptographically secure random UUIDs
- [ ] No hardcoded secrets or keys in code
- [ ] Token expiry values enforced (not optional)

## Validation Gates

### Gate 1: Linting
```bash
npm run lint -- services/authService.js config/jwt.js
```
**Expected:** No errors

### Gate 2: Unit Tests
```bash
npm test -- authService.test.js
```
**Expected:** All 5 new tests pass

### Gate 3: Full Test Suite
```bash
npm test
```
**Expected:** No regressions

### Gate 4: Security Check
```bash
npm audit
```
**Expected:** No high/critical vulnerabilities

## Notes

- **RS256 vs HS256**: RS256 chosen because public key can be shared for token verification without compromising security. HS256 requires shared secret, which is risky if multiple services verify tokens.
- **Refresh Token Rotation**: Future enhancement - invalidate old refresh token when issuing new one (not in this work-order).
- **Token Revocation**: Refresh tokens in Redis enable revocation (delete from Redis). Access tokens cannot be revoked (short expiry mitigates risk).
- **Key Generation**: Generate RSA key pair with:
  ```bash
  # Generate private key
  openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:2048

  # Extract public key
  openssl rsa -pubout -in private_key.pem -out public_key.pem
  ```

## Confidence Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Context Completeness | 9/10 | All files, dependencies, code excerpts provided |
| Gotchas Documented | 8/10 | Key format and connection pool issues covered |
| Test Coverage | 9/10 | 5 specific test cases with assertions |
| Validation Gates | 8/10 | Lint, test, and security commands provided |
| **Overall** | **8.5/10** | Ready for subagent delegation |

## Related Work-Orders

- **Depends on**: Work-Order 001 (Redis setup and configuration)
- **Depends on**: Work-Order 002 (User model and registration)
- **Blocks**: Work-Order 004 (Login endpoint - needs tokens)
- **Blocks**: Work-Order 005 (Token refresh endpoint - needs tokens)
```

## Work-Order Best Practices

### Keep Context Minimal

❌ **Too Much Context**: Including entire PRD, all related files, full codebase structure
✅ **Minimal Context**: Only the specific section of PRD, only files to be modified, only relevant code excerpts

### Be Specific About Tests

❌ **Vague**: "Write tests for token generation"
✅ **Specific**: Exact test cases with expected behavior and assertions

### Follow TDD Strictly

Work-orders must enforce RED → GREEN → REFACTOR:
1. Write failing test
2. Minimal implementation
3. Refactor while tests stay green

### Define "Done" Clearly

Success criteria should be unambiguous checkboxes:
- [ ] Specific functionality works
- [ ] Specific tests pass
- [ ] Specific baselines met

### Isolate Dependencies

If a work-order depends on another:
- **Block the dependent work-order** until prerequisites complete
- **Document the dependency** in "Related Work-Orders"
- **Don't include incomplete dependencies** in the work-order context

## Work-Order Workflow

### 1. Generate Work-Order

```bash
/blueprint:work-order
```

Claude analyzes project state and creates next logical work-order.

### 2. Review Work-Order

Check that:
- Objective is clear and specific
- Context is minimal but sufficient
- Tests are well-defined
- Success criteria are measurable

Edit if needed before execution.

### 3. Execute with Subagent

Hand work-order to appropriate subagent:

```bash
# For implementation tasks
<Task subagent_type="general-purpose" prompt="Execute work-order 003">

# For code quality focused tasks
<Task subagent_type="code-refactoring" prompt="Execute work-order 003">
```

### 4. Verify Completion

After subagent completes:
- [ ] All success criteria checked
- [ ] All tests pass
- [ ] No regressions in existing tests
- [ ] Code follows project skills

### 5. Mark Complete

Move work-order to completed:
```bash
mv .claude/blueprints/work-orders/003-jwt-token-generation.md \
   .claude/blueprints/work-orders/completed/003-jwt-token-generation.md
```

Update work-overview:
```markdown
### Completed
- ✅ Work-Order 003: JWT Token Generation (commit: abc123f)
```

## Work-Order Numbering

Use sequential numbering with zero-padding:
- `001-first-task.md`
- `002-second-task.md`
- `010-tenth-task.md`
- `100-hundredth-task.md`

This keeps work-orders sorted chronologically.

## Work-Order Organization

```
.claude/blueprints/work-orders/
├── 001-database-setup.md
├── 002-user-model.md
├── 003-jwt-tokens.md         # Current work
├── 004-login-endpoint.md      # Pending (blocked by 003)
├── 005-refresh-endpoint.md    # Pending (blocked by 003)
├── completed/
│   ├── 001-database-setup.md
│   └── 002-user-model.md
└── archived/
    └── 999-deprecated-approach.md  # Obsolete work-orders
```

## Templates for Common Task Types

### API Endpoint Work-Order

```markdown
# Work-Order NNN: Implement [HTTP Method] [Endpoint Path]

## Objective
Implement [endpoint] that [what it does].

## TDD Requirements
- Test 1: Valid request returns correct status and response shape
- Test 2: Invalid input returns 400 with validation errors
- Test 3: Authorization check (if needed)
- Test 4: Edge cases and error conditions

## Implementation Steps
1. Write integration test (expected: FAIL)
2. Create route handler
3. Implement controller method
4. Implement service logic
5. All tests pass
```

### Database Migration Work-Order

```markdown
# Work-Order NNN: Create [Table/Schema] Migration

## Objective
Create database migration for [table/schema].

## TDD Requirements
- Test 1: Migration runs without errors
- Test 2: Schema matches specification
- Test 3: Rollback works correctly
- Test 4: Data integrity constraints enforced

## Implementation Steps
1. Write migration up/down scripts
2. Test migration in development
3. Test rollback
4. Update models to match schema
```

### UI Component Work-Order

```markdown
# Work-Order NNN: Implement [Component Name]

## Objective
Create [component] that displays/handles [functionality].

## TDD Requirements
- Test 1: Component renders with required props
- Test 2: User interactions work correctly
- Test 3: Edge cases (empty state, loading, error)
- Test 4: Accessibility requirements met

## Implementation Steps
1. Write component tests (expected: FAIL)
2. Create component with minimal implementation
3. Style component
4. Add interaction handlers
5. All tests pass
```

## Integration with Blueprint Development

Work-orders enable:

1. **Isolated Subagent Execution** - Hand complete context to subagent
2. **Parallel Development** - Multiple work-orders executed concurrently
3. **TDD Enforcement** - Tests specified before implementation
4. **Progress Tracking** - Clear completion criteria
5. **Knowledge Transfer** - Document what was done and why

Work-orders bridge the gap between high-level PRDs and low-level implementation, providing exactly the context needed for focused, testable development.
