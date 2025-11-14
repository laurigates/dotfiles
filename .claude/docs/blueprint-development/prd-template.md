# PRD Template

Use this template to create Product Requirements Documents (PRDs) for Blueprint Development projects.

## Template

```markdown
# PRD: [Feature/Component Name]

## Overview
Brief description of what this feature/component does and why it's needed.

**Problem Statement:** What problem does this solve?
**Target Users:** Who will use this feature?
**Priority:** Critical / High / Medium / Low

## Requirements

### Functional Requirements
- **FR1**: [Specific, testable requirement]
- **FR2**: [Specific, testable requirement]
- **FR3**: [Specific, testable requirement]

### Non-Functional Requirements
- **Performance**: [Specific performance targets with metrics]
- **Security**: [Security requirements and constraints]
- **Scalability**: [Scaling requirements and limits]
- **Reliability**: [Uptime, error rate, recovery requirements]

## Technical Decisions

### Architecture
**Decision:** [Architectural approach]
**Rationale:** [Why this approach was chosen]
**Alternatives Considered:** [Other options and why they were rejected]
**Trade-offs:** [What we're sacrificing for this choice]

### Technology Stack
- **Language/Framework**: [Choice and version] - [Why]
- **Database**: [Choice and version] - [Why]
- **Libraries**: [Key dependencies] - [Why]
- **External Services**: [Third-party integrations] - [Why]

### Data Model
[Describe key entities, relationships, and schema decisions]

### API Design
[Describe API structure, endpoints, request/response formats]

### Security Model
[Authentication, authorization, data protection, input validation]

## Success Criteria

### Acceptance Criteria
- [ ] [Specific, testable criterion 1]
- [ ] [Specific, testable criterion 2]
- [ ] [Specific, testable criterion 3]

### Test Coverage Requirements
- Minimum overall coverage: [e.g., 80%]
- Critical path coverage: [e.g., 100%]
- Edge case coverage: [e.g., All error paths tested]

### Performance Baselines
- [Metric 1]: [Target value]
- [Metric 2]: [Target value]
- [Metric 3]: [Target value]

### Security Compliance
- [ ] OWASP Top 10 compliance
- [ ] Input validation on all endpoints
- [ ] No hardcoded secrets
- [ ] [Other security requirements]

## TDD Requirements

### Test Strategy
Specify which types of tests are required and what they should cover.

**Unit Tests:**
- [Component 1] - [What to test]
- [Component 2] - [What to test]

**Integration Tests:**
- [Integration point 1] - [What to test]
- [Integration point 2] - [What to test]

**End-to-End Tests:**
- [User flow 1] - [What to test]
- [User flow 2] - [What to test]

### Test-First Implementation
All implementation must follow RED → GREEN → REFACTOR:
1. Write failing test describing desired behavior
2. Run tests to confirm failure
3. Write minimal implementation to pass
4. Run tests to confirm success
5. Refactor while keeping tests green

### Critical Test Cases
List critical scenarios that MUST be tested:
- [Scenario 1]: [Expected behavior]
- [Scenario 2]: [Expected behavior]
- [Scenario 3]: [Expected behavior]

## Constraints

### Technical Constraints
- [Constraint 1]: [Description and impact]
- [Constraint 2]: [Description and impact]

### Business Constraints
- [Budget limits, timeline, resource availability]

### Compliance Constraints
- [Regulatory or legal requirements]

## Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| [Risk 1] | High/Med/Low | High/Med/Low | [How to mitigate] |
| [Risk 2] | High/Med/Low | High/Med/Low | [How to mitigate] |

## Dependencies

### Internal Dependencies
- [Component/Feature A] must be completed first
- [Component/Feature B] must be available

### External Dependencies
- [Third-party service X] integration required
- [Library Y] must be evaluated and approved

## Implementation Phases

### Phase 1: [Phase Name]
**Goal:** [What this phase achieves]
**Deliverables:**
- [ ] [Deliverable 1]
- [ ] [Deliverable 2]

### Phase 2: [Phase Name]
**Goal:** [What this phase achieves]
**Deliverables:**
- [ ] [Deliverable 1]
- [ ] [Deliverable 2]

### Phase 3: [Phase Name]
**Goal:** [What this phase achieves]
**Deliverables:**
- [ ] [Deliverable 1]
- [ ] [Deliverable 2]

## Out of Scope
Explicitly list what is NOT included in this PRD:
- [Out of scope item 1]
- [Out of scope item 2]

## Open Questions
Questions that need to be resolved before or during implementation:
- **Q1**: [Question]
  - **Decision needed by**: [Date]
  - **Owner**: [Who will decide]
- **Q2**: [Question]
  - **Decision needed by**: [Date]
  - **Owner**: [Who will decide]

## References
- [Link to design docs]
- [Link to API specifications]
- [Link to related PRDs]
- [Link to external documentation]

## Changelog

### [Date] - [Version]
- [Change description]
- [Reason for change]
```

## Example PRD

Here's a concrete example following the template:

```markdown
# PRD: User Authentication System

## Overview
Implement secure JWT-based authentication with email/password registration, login, and password reset functionality.

**Problem Statement:** Users need a secure way to create accounts and access protected resources.
**Target Users:** All application users
**Priority:** Critical

## Requirements

### Functional Requirements
- **FR1**: Users can register with email and password
- **FR2**: Users can login with valid credentials and receive JWT tokens
- **FR3**: Users can reset password via email link
- **FR4**: Users can refresh access tokens using refresh tokens
- **FR5**: Invalid login attempts are rate-limited

### Non-Functional Requirements
- **Performance**: Token generation < 10ms, login endpoint p95 < 200ms
- **Security**: OWASP Top 10 compliance, bcrypt password hashing, no plaintext credentials
- **Scalability**: Support 10,000 concurrent users
- **Reliability**: 99.9% uptime, graceful degradation if email service unavailable

## Technical Decisions

### Architecture
**Decision:** Layered architecture (Routes → Controllers → Services → Repositories)
**Rationale:** Clear separation of concerns, testable business logic, easy to maintain
**Alternatives Considered:**
- Monolithic routes with inline logic (rejected: hard to test, violates SRP)
- Microservices (rejected: overkill for current scale)
**Trade-offs:** More files and boilerplate, but better maintainability

### Technology Stack
- **Framework**: Express.js 4.18 - Industry standard, excellent ecosystem
- **Authentication**: passport.js + jsonwebtoken - Well-tested, flexible
- **Database**: PostgreSQL 15 - ACID compliance, good JSON support
- **Password Hashing**: bcrypt (cost factor 12) - Industry standard, resistant to GPU attacks
- **Token Storage**: Redis 7 - Fast, TTL support for refresh tokens
- **Email Service**: SendGrid - Reliable, good deliverability

### Data Model
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  email_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE refresh_tokens (
  token VARCHAR(255) PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### API Design
```
POST /auth/register
  Request: { email, password }
  Response: { userId, accessToken, refreshToken }

POST /auth/login
  Request: { email, password }
  Response: { accessToken, refreshToken }

POST /auth/refresh
  Request: { refreshToken }
  Response: { accessToken, refreshToken }

POST /auth/logout
  Request: { refreshToken }
  Response: { success: true }

POST /auth/forgot-password
  Request: { email }
  Response: { success: true }

POST /auth/reset-password
  Request: { token, newPassword }
  Response: { success: true }
```

### Security Model
- **Password Storage**: bcrypt with cost factor 12, salted automatically
- **JWT Signing**: RS256 (asymmetric) with private key in environment variable
- **Token Expiry**: Access tokens 15min, refresh tokens 7 days
- **Rate Limiting**: 5 requests/min per IP on auth endpoints
- **Input Validation**: joi schemas for all request bodies
- **Error Messages**: Generic "Invalid credentials" (don't leak user existence)

## Success Criteria

### Acceptance Criteria
- [ ] Users can register with valid email and password
- [ ] Users receive error on duplicate email registration
- [ ] Users can login with correct credentials
- [ ] Users receive error on invalid credentials
- [ ] Login attempts are rate-limited after 5 failures
- [ ] Users can reset password via email link
- [ ] Access tokens expire after 15 minutes
- [ ] Refresh tokens work for 7 days then expire

### Test Coverage Requirements
- Minimum overall coverage: 90%
- Critical path coverage: 100% (auth flows)
- Edge case coverage: All error paths tested

### Performance Baselines
- Token generation: < 10ms
- Registration endpoint: p95 < 300ms
- Login endpoint: p95 < 200ms
- Refresh endpoint: p95 < 100ms
- Password reset: p95 < 500ms (includes email send)

### Security Compliance
- [ ] OWASP Top 10 compliance verified
- [ ] Input validation on all endpoints
- [ ] No hardcoded secrets (environment variables)
- [ ] Password strength requirements enforced
- [ ] Rate limiting implemented on auth endpoints
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (output encoding)
- [ ] CSRF protection (if needed for session-based flows)

## TDD Requirements

### Test Strategy

**Unit Tests:**
- `authService` - Token generation, password hashing validation
- `userRepository` - CRUD operations on users table
- `validators` - Email format, password strength validation

**Integration Tests:**
- All auth API endpoints with real database (test containers)
- Rate limiting behavior
- Token refresh flow
- Password reset flow end-to-end

**End-to-End Tests:**
- Complete user registration → login → access protected resource flow
- Password reset flow from email to new login

### Test-First Implementation
All implementation must follow RED → GREEN → REFACTOR:
1. Write failing test describing desired behavior
2. Run `npm test` to confirm failure
3. Write minimal implementation to pass
4. Run `npm test` to confirm success
5. Refactor while keeping tests green

### Critical Test Cases
- **Registration with valid data**: Creates user, returns tokens
- **Registration with duplicate email**: Returns 400 error
- **Registration with weak password**: Returns 400 error with requirements
- **Login with valid credentials**: Returns tokens
- **Login with invalid credentials**: Returns 401 error (generic message)
- **Login after 5 failed attempts**: Returns 429 rate limit error
- **Token refresh with valid refresh token**: Returns new tokens
- **Token refresh with expired token**: Returns 401 error
- **Token refresh with invalid token**: Returns 401 error
- **Password reset request**: Sends email with reset link
- **Password reset with valid token**: Updates password, allows login
- **Password reset with expired token**: Returns 400 error

## Constraints

### Technical Constraints
- Must integrate with existing Express.js application
- Must use existing PostgreSQL database instance
- Redis required for refresh token storage
- Email service (SendGrid) requires API key

### Business Constraints
- Must launch within 2 weeks for beta testing
- Budget: $50/month for email service

### Compliance Constraints
- GDPR compliance: Users can delete their accounts
- Password data must never be logged or exposed

## Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Email service unavailable during password reset | High | Low | Queue emails in database, retry with exponential backoff |
| JWT private key compromised | Critical | Very Low | Rotate keys immediately, invalidate all tokens, force re-login |
| bcrypt cost factor too high causing slow logins | Medium | Medium | Load test and adjust cost factor if p95 > 200ms |
| Rate limiting too aggressive blocking legitimate users | Medium | Medium | Monitor false positive rate, adjust limits based on data |

## Dependencies

### Internal Dependencies
- Database schema must be created and migrated
- Email templates must be designed
- Environment variables must be configured in deployment

### External Dependencies
- SendGrid account and API key required
- Redis instance must be provisioned
- Public/private key pair must be generated for JWT signing

## Implementation Phases

### Phase 1: Core Authentication
**Goal:** Basic registration and login with JWT tokens
**Deliverables:**
- [ ] User registration endpoint with validation
- [ ] Login endpoint with JWT generation
- [ ] Password hashing with bcrypt
- [ ] Unit and integration tests for auth flows

### Phase 2: Token Management
**Goal:** Refresh tokens and logout functionality
**Deliverables:**
- [ ] Refresh token generation and storage in Redis
- [ ] Token refresh endpoint
- [ ] Logout endpoint (invalidate refresh token)
- [ ] Tests for token lifecycle

### Phase 3: Password Reset
**Goal:** Complete password reset flow via email
**Deliverables:**
- [ ] Forgot password endpoint (generates reset token)
- [ ] Email template for password reset
- [ ] Reset password endpoint (validates token, updates password)
- [ ] End-to-end tests for password reset flow

### Phase 4: Security Hardening
**Goal:** Rate limiting, monitoring, security audit
**Deliverables:**
- [ ] Rate limiting on all auth endpoints
- [ ] Security audit (OWASP Top 10 checklist)
- [ ] Monitoring and alerting for auth failures
- [ ] Load testing to verify performance baselines

## Out of Scope
- Social authentication (Google, GitHub, etc.) - Future PRD
- Two-factor authentication (2FA) - Future PRD
- Email verification requirement on registration - Future enhancement
- Account lockout after failed attempts - Future enhancement
- Password expiry and rotation - Not needed for current use case

## Open Questions
- **Q1**: Should we require email verification before allowing login?
  - **Decision needed by**: Sprint planning (Day 1)
  - **Owner**: Product Manager
  - **Update**: Decided NO for beta, add in Phase 2
- **Q2**: What should the rate limit be for login attempts?
  - **Decision needed by**: Before Phase 1 implementation
  - **Owner**: Security Team
  - **Update**: 5 requests/min per IP (can adjust based on monitoring)

## References
- [OWASP Authentication Cheatsheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [JWT Best Practices](https://datatracker.ietf.org/doc/html/rfc8725)
- [bcrypt documentation](https://github.com/kelektiv/node.bcrypt.js)
- [passport.js JWT strategy](http://www.passportjs.org/packages/passport-jwt/)

## Changelog

### 2024-01-15 - v1.0
- Initial PRD created
- Technical decisions finalized

### 2024-01-16 - v1.1
- Updated: Rate limit decision (5 req/min)
- Updated: Email verification deferred to Phase 2
```

## Tips for Writing PRDs

### Be Specific
❌ Bad: "The system should be fast"
✅ Good: "Login endpoint p95 response time < 200ms"

### Include Rationale
❌ Bad: "Use PostgreSQL"
✅ Good: "Use PostgreSQL - ACID compliance required for financial transactions, JSON support for flexible user metadata"

### Make Tests Testable
❌ Bad: "Registration should work"
✅ Good: "POST /auth/register with valid email/password returns 201 and JWT tokens"

### Document Trade-offs
Every technical decision has trade-offs. Document them:
- What you gain
- What you sacrifice
- Why the trade-off is acceptable

### Define "Done"
Acceptance criteria should be unambiguous checkboxes that define when the feature is complete.

### Specify TDD Requirements
Explicitly list critical test cases so implementers know what to test first.

## PRD Best Practices

1. **Start with the problem** - Why are we building this?
2. **Define success clearly** - What does "done" look like?
3. **Document decisions** - Why did we choose this approach?
4. **Include constraints** - What limits our options?
5. **Identify risks** - What could go wrong?
6. **Specify tests** - What must be tested?
7. **Update as you learn** - PRDs evolve during implementation
8. **Reference external docs** - Link to design docs, APIs, standards

## Integration with Blueprint Development

PRDs in Blueprint Development serve multiple purposes:

1. **Requirements specification** - What to build
2. **Architecture documentation** - How to structure the code
3. **Skill generation input** - Source material for generating project-specific skills
4. **Work-order context** - Background information for isolated tasks
5. **Project continuity** - Enables `/project:continue` to understand goals

Well-written PRDs enable Blueprint Development to generate high-quality, project-specific skills and commands that enforce your architectural decisions, testing strategies, and quality standards automatically.
