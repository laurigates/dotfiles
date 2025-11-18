# Blueprint Development Workflow

This document provides a complete walkthrough of the Blueprint Development workflow from project initialization through feature implementation.

## Overview

```
PRDs → Generate Skills/Commands → Development Loop → Work-Orders → Subagent Execution
  ↑                                      ↓
  └──────────── Iteration & Refinement ───┘
```

## Phase 1: Project Initialization

### Step 1: Initialize Blueprint Structure

```bash
cd your-project/
/blueprint:init
```

**What happens:**
- Creates `.claude/blueprints/` directory structure
- Creates `.claude/blueprints/prds/` for requirements
- Creates `.claude/blueprints/work-orders/` for task packages
- Creates placeholder `work-overview.md`
- Adds `.claude/` to `.gitignore` (optional, can commit for team sharing)

**Result:** Project is ready for PRD creation.

### Step 2: Write PRDs

Create requirement documents in `.claude/blueprints/prds/`:

```markdown
# .claude/blueprints/prds/user-authentication.md

## Feature: User Authentication

### Overview
Implement JWT-based authentication with refresh tokens.

### Requirements
- Email/password registration and login
- JWT access tokens (15min expiry)
- Refresh tokens (7 day expiry)
- Password reset flow via email

### Technical Decisions
- **Auth Library**: passport.js with JWT strategy
- **Password Hashing**: bcrypt with cost factor 12
- **Token Storage**: Redis for refresh tokens
- **Email Service**: SendGrid for password reset

### Success Criteria
- [ ] All auth endpoints have >90% test coverage
- [ ] Authentication flow tested with integration tests
- [ ] Rate limiting on auth endpoints (5 req/min)
- [ ] Security audit passes (OWASP Top 10)

### TDD Requirements
Write tests first for:
- Registration validation (email format, password strength)
- Login flow (success, invalid credentials, account locked)
- Token refresh flow
- Password reset flow
```

**PRD Best Practices:**
- One PRD per major feature or architectural component
- Include technical decisions and rationale
- Specify TDD requirements explicitly
- Define clear success criteria
- Document constraints and trade-offs

### Step 3: Generate Skills

```bash
/blueprint:generate-skills
```

**What happens:**
Claude analyzes all PRDs and generates project-specific skills in four domains:

**1. Architecture Patterns** (`.claude/skills/architecture-patterns/`)
```yaml
---
name: architecture-patterns
description: "Architecture patterns and code organization for this project"
---

# Architecture Patterns

## Project Structure
This project uses a layered architecture:
- `routes/` - Express route handlers
- `controllers/` - Business logic
- `services/` - External service integrations
- `models/` - Database models (Sequelize ORM)
- `middleware/` - Express middleware (auth, validation)

## Dependency Injection
Use constructor injection for services:
```javascript
class UserController {
  constructor(userService, emailService) {
    this.userService = userService;
    this.emailService = emailService;
  }
}
```

## Error Handling
Use centralized error handling middleware...
```

**2. Testing Strategies** (`.claude/skills/testing-strategies/`)
```yaml
---
name: testing-strategies
description: "TDD workflow, testing patterns, and coverage requirements for this project"
---

# Testing Strategies

## TDD Workflow
Follow strict RED → GREEN → REFACTOR:
1. Write a failing test describing desired behavior
2. Run test suite to confirm failure
3. Write minimal implementation to pass the test
4. Run test suite to confirm success
5. Refactor for clarity/performance while keeping tests green

## Test Structure
- `tests/unit/` - Unit tests for individual functions/classes
- `tests/integration/` - Integration tests for API endpoints
- `tests/e2e/` - End-to-end tests for user flows

## Mocking Patterns
- Mock external services (SendGrid, Redis) in unit tests
- Use real services in integration tests (test containers)
- Never mock the system under test

## Coverage Requirements
- Minimum 80% overall coverage
- 100% coverage for auth-related code
- All edge cases and error paths tested
```

**3. Implementation Guides** (`.claude/skills/implementation-guides/`)
```yaml
---
name: implementation-guides
description: "How to implement specific feature types in this project"
---

# Implementation Guides

## API Endpoint Implementation

### 1. Define Route (tests/integration/routes/)
```javascript
describe('POST /auth/login', () => {
  it('should return JWT on valid credentials', async () => {
    // Test implementation
  });
});
```

### 2. Create Route Handler (routes/)
```javascript
router.post('/auth/login', authController.login);
```

### 3. Implement Controller (controllers/)
```javascript
async login(req, res, next) {
  try {
    const { email, password } = req.body;
    const tokens = await this.authService.login(email, password);
    res.json(tokens);
  } catch (error) {
    next(error);
  }
}
```

### 4. Implement Service Logic (services/)
```javascript
async login(email, password) {
  const user = await this.userService.findByEmail(email);
  if (!user || !await bcrypt.compare(password, user.password)) {
    throw new UnauthorizedError('Invalid credentials');
  }
  return this.generateTokens(user);
}
```
```

**4. Quality Standards** (`.claude/skills/quality-standards/`)
```yaml
---
name: quality-standards
description: "Code review criteria, performance baselines, and security standards for this project"
---

# Quality Standards

## Code Review Checklist
- [ ] All functions have unit tests
- [ ] Integration tests cover happy path and error cases
- [ ] No hardcoded credentials or secrets
- [ ] Input validation on all API endpoints
- [ ] Error messages don't leak sensitive info
- [ ] Rate limiting on auth endpoints
- [ ] SQL queries use parameterized statements
- [ ] Dependencies are up-to-date (npm audit)

## Performance Baselines
- API response time p95 < 200ms
- Database queries < 50ms
- JWT generation < 10ms

## Security Standards
- OWASP Top 10 compliance
- Password hashing with bcrypt (cost factor 12)
- JWT tokens signed with RS256
- HTTPS only in production
- CORS configured for specific origins
```

**Result:** Project-specific skills are generated and immediately available to Claude.

### Step 4: Generate Commands

```bash
/blueprint:generate-commands
```

**What happens:**
Claude generates workflow commands based on PRDs and project structure:

**1. `/project:continue`** - Resume development
```markdown
---
description: "Analyze project state and continue development where left off"
allowed_tools: [Read, Bash, Grep, Glob]
---

Analyze the current project state and continue development:

1. Check git status (uncommitted work, current branch)
2. Read all PRDs in `.claude/blueprints/prds/`
3. Read `work-overview.md` to understand current phase
4. Check recent work-orders to see completed and pending tasks
5. Identify next logical task based on PRDs and project state
6. Begin work following TDD workflow (tests first)

If starting a new feature, create a work-order first with `/blueprint:work-order`.
```

**2. `/project:test-loop`** - TDD automation
```markdown
---
description: "Run test → fix → refactor loop with TDD workflow"
allowed_tools: [Read, Edit, Bash]
---

Run automated TDD cycle:

1. Run test suite: `npm test`
2. If tests fail:
   - Analyze failure output
   - Make minimal fix to pass the test
   - Re-run tests to confirm
3. If tests pass:
   - Check for refactoring opportunities
   - Refactor while keeping tests green
4. Repeat until no failures or refactoring needed

Stop and report when:
- All tests pass
- No obvious refactoring opportunities
- User intervention needed
```

**Result:** Commands are available for workflow automation.

## Phase 2: Development Loop

### Step 1: Start or Resume Work

```bash
/project:continue
```

**What Claude does:**
1. Runs `git status` to check for uncommitted work
2. Reads PRDs to understand project goals
3. Reads `work-overview.md` for current phase
4. Checks `work-orders/` for completed and pending tasks
5. Identifies next logical task
6. Begins work following TDD workflow

**Example output:**
```
Project: User Authentication System
Current Branch: main
Uncommitted Changes: None

PRDs Found:
- user-authentication.md (Registration, Login, Password Reset)
- api-design.md (REST API structure)

Work Overview: Phase 1 - Core Authentication
- ✅ Database schema created
- ✅ User model implemented
- ⏳ Registration endpoint (in progress)
- ⏹️ Login endpoint (pending)

Next Task: Complete registration endpoint tests and implementation

Starting TDD workflow for POST /auth/register...
```

### Step 2: TDD Workflow

Claude automatically follows TDD based on project skills:

**RED - Write Failing Test:**
```javascript
// tests/integration/auth.test.js
describe('POST /auth/register', () => {
  it('should create user with valid data', async () => {
    const response = await request(app)
      .post('/auth/register')
      .send({
        email: 'test@example.com',
        password: 'SecurePass123!'  // pragma: allowlist secret
      });

    expect(response.status).toBe(201);
    expect(response.body).toHaveProperty('userId');
  });
});
```

Run tests: `npm test` → **FAILS (expected)**

**GREEN - Minimal Implementation:**
```javascript
// routes/auth.js
router.post('/register', async (req, res) => {
  const { email, password } = req.body;
  const user = await User.create({ email, password });
  res.status(201).json({ userId: user.id });
});
```

Run tests: `npm test` → **PASSES**

**REFACTOR - Improve Code:**
```javascript
// Extract to controller
router.post('/register', authController.register);

// controllers/authController.js
async register(req, res, next) {
  try {
    const { email, password } = req.body;
    const userId = await this.authService.register(email, password);
    res.status(201).json({ userId });
  } catch (error) {
    next(error);
  }
}

// services/authService.js
async register(email, password) {
  const hashedPassword = await bcrypt.hash(password, 12);
  const user = await this.userRepository.create({ email, password: hashedPassword });
  return user.id;
}
```

Run tests: `npm test` → **STILL PASSES**

### Step 3: Commit Incrementally

After completing each test cycle:
```bash
git add tests/integration/auth.test.js routes/auth.js
git commit -m "feat(auth): implement user registration endpoint

Implements POST /auth/register with:
- Email and password validation
- bcrypt password hashing (cost factor 12)
- User creation in database

Tests include:
- Valid registration flow
- Duplicate email handling
- Invalid input validation

Refs: #123"
```

**Commit best practices:**
- Commit after each RED → GREEN → REFACTOR cycle
- Use conventional commits (feat, fix, refactor, test, docs)
- Reference PRD or issue number
- Include tests in the same commit as implementation

### Step 4: Update Work Overview

After completing a significant milestone, update `work-overview.md`:
```markdown
# Work Overview: User Authentication System

## Current Phase: Phase 1 - Core Authentication

### Completed
- ✅ Database schema created
- ✅ User model implemented with password hashing
- ✅ Registration endpoint (POST /auth/register)
  - Tests: Unit tests for validation, integration tests for endpoint
  - Implementation: Controller, Service, Repository layers
  - Commit: abc123f

### In Progress
- ⏳ Login endpoint (POST /auth/login)
  - Tests written, implementation started

### Pending
- ⏹️ JWT token generation and validation
- ⏹️ Refresh token flow
- ⏹️ Password reset flow

## Next Steps
1. Complete login endpoint implementation
2. Implement JWT token generation
3. Add refresh token mechanism
4. Implement password reset flow
```

## Phase 3: Work-Order Generation

### When to Create Work-Orders

Create work-orders for:
- Complex features requiring isolated focus
- Tasks suitable for subagent execution
- Parallel work streams
- Tasks with well-defined scope and context

### Generate Work-Order

```bash
/blueprint:work-order
```

**What Claude does:**
1. Analyzes current PRD and project state
2. Identifies next logical work unit
3. Determines minimal required context
4. Generates work-order document
5. Saves to `.claude/blueprints/work-orders/NNN-task-name.md`

**Example work-order:**
```markdown
# Work-Order 003: Implement JWT Token Generation

## Objective
Implement JWT access token and refresh token generation for authenticated users.

## Context

### Required Files
- `services/authService.js` - Add token generation methods
- `models/refreshToken.js` - Create refresh token model
- `tests/unit/services/authService.test.js` - Add token generation tests

### PRD Reference
See `.claude/blueprints/prds/user-authentication.md` - JWT Token Management section

### Technical Decisions
- Use `jsonwebtoken` library for JWT generation
- Access tokens: 15 minute expiry, RS256 signing
- Refresh tokens: 7 day expiry, stored in Redis
- Private key stored in environment variable `JWT_PRIVATE_KEY`

### Existing Code
```javascript
// services/authService.js (relevant excerpt)
class AuthService {
  async register(email, password) {
    // ... existing registration logic
  }
}
```

## TDD Requirements

### Test 1: Generate Access Token
```javascript
describe('generateAccessToken', () => {
  it('should generate valid JWT with user claims', () => {
    const token = authService.generateAccessToken(user);
    const decoded = jwt.verify(token, publicKey);
    expect(decoded).toHaveProperty('userId', user.id);
    expect(decoded).toHaveProperty('email', user.email);
  });
});
```

### Test 2: Generate Refresh Token
```javascript
describe('generateRefreshToken', () => {
  it('should create refresh token in Redis', async () => {
    const refreshToken = await authService.generateRefreshToken(user);
    const stored = await redis.get(`refresh:${refreshToken}`);
    expect(stored).toBe(user.id.toString());
  });
});
```

## Implementation Steps

1. Write tests for `generateAccessToken(user)` - should fail
2. Implement `generateAccessToken(user)` - tests should pass
3. Refactor if needed
4. Write tests for `generateRefreshToken(user)` - should fail
5. Implement `generateRefreshToken(user)` - tests should pass
6. Refactor if needed
7. Update `login` and `register` methods to return tokens
8. Verify all tests pass

## Success Criteria
- [ ] Access tokens generated with correct claims and expiry
- [ ] Refresh tokens stored in Redis with 7-day TTL
- [ ] All tests pass (unit and integration)
- [ ] Token generation < 10ms (performance baseline)
- [ ] No hardcoded secrets (use environment variables)

## Notes
- Use RS256 (asymmetric) not HS256 (symmetric) for JWT signing
- Rotate refresh tokens on use (refresh token rotation pattern)
- Rate limit token generation endpoints
```

### Execute Work-Order with Subagent

Hand the work-order to a subagent:
```bash
# Option 1: Use Task tool with isolated context
<execute work-order 003 with general-purpose subagent>

# Option 2: Use specialized subagent
<execute work-order 003 with code-refactoring subagent>
```

**Benefits of work-orders:**
- **Isolated context** - Subagent has exactly what it needs
- **TDD enforced** - Tests are specified in the work-order
- **Parallel execution** - Multiple work-orders can run concurrently
- **Clear success criteria** - Easy to verify completion

## Phase 4: Iteration & Refinement

### Review and Refine Skills

As patterns emerge during development, update skills:

**Example: Architecture pattern evolves**
```bash
vim .claude/skills/architecture-patterns/SKILL.md

# Update to reflect new pattern
## Service Layer Pattern
All business logic must be in service layer:
- Services are stateless
- Services use dependency injection
- Services return data, controllers format responses
```

**Skills update immediately** - no rebuild needed.

### Update PRDs

As requirements change or decisions evolve:
```bash
vim .claude/blueprints/prds/user-authentication.md

# Add new requirement
### Two-Factor Authentication
Add TOTP-based 2FA as optional security enhancement...
```

Then regenerate skills:
```bash
/blueprint:generate-skills
```

### Continue Where You Left Off

Switch between projects easily:
```bash
cd project-a/
/project:continue
# Resumes project A exactly where you left off

cd ../project-b/
/project:continue
# Resumes project B with its own context
```

## Advanced Patterns

### Parallel Development Streams

Create multiple work-orders for parallel execution:
```bash
/blueprint:work-order    # Creates 004-implement-password-reset.md
/blueprint:work-order    # Creates 005-add-rate-limiting.md
/blueprint:work-order    # Creates 006-setup-email-service.md

# Execute in parallel with different subagents
<execute work-order 004 with subagent-1>
<execute work-order 005 with subagent-2>
<execute work-order 006 with subagent-3>
```

### Custom Work-Order Templates

Create templates for common task types:
```bash
.claude/blueprints/templates/
├── api-endpoint-work-order.md
├── database-migration-work-order.md
└── ui-component-work-order.md
```

### CI/CD Integration

Generate work-orders from CI failures:
```yaml
# .github/workflows/ci.yml
- name: Generate work-order on failure
  if: failure()
  run: |
    claude --command blueprint:work-order --context "CI failure: ${{ github.event.workflow_run.conclusion }}"
```

## Summary

Blueprint Development workflow:

1. **Initialize** - `/blueprint:init` creates structure
2. **Plan** - Write PRDs defining features and architecture
3. **Generate** - Create skills and commands from PRDs
4. **Develop** - `/project:continue` resumes work with TDD
5. **Delegate** - `/blueprint:work-order` creates isolated tasks
6. **Execute** - Subagents work on isolated work-orders
7. **Iterate** - Refine skills and PRDs as patterns emerge

**Result:** Self-documenting, AI-native development with consistent patterns, automated workflows, and efficient subagent delegation.
