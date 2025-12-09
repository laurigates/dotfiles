---
name: multi-agent-workflows
description: |
  Orchestrate complex multi-agent workflows for development, infrastructure, and
  research. Provides workflow templates, agent sequences, and integration patterns.
  Use when planning complex projects, coordinating multiple agents, designing
  API development workflows, or infrastructure setup workflows.
---

# Multi-Agent Workflow Orchestration

## Description

Proven patterns for coordinating complex multi-agent workflows across development, infrastructure, and research tasks. This skill provides battle-tested workflow templates that ensure proper agent sequencing, dependency management, and integration.

## When to Use

Automatically apply this skill when:
- User requests complex projects requiring multiple specialties (backend + frontend, code + infrastructure)
- Task involves multiple sequential or parallel phases
- Planning large-scale development work (API projects, full-stack apps, infrastructure setup)
- Need to coordinate between different agent specializations
- Project requires clear handoff points between phases

## Key Workflow Patterns

### 1. Sequential Workflows
**Use when**: Tasks have clear dependencies (A must complete before B starts)

**Pattern**: Linear chain with checkpoints
```
Research → Planning → Implementation → Testing → Documentation → Deployment
```

**Example**: API Development
- Research assistant: Analyze requirements, research best practices
- Git expert: Initialize repository with proper structure
- Python developer: Implement API endpoints, database models
- Security auditor: Review authentication, scan for vulnerabilities
- Test architect: Create comprehensive test suite
- Documentation expert: Generate API documentation
- Pipeline engineer: Set up CI/CD automation

### 2. Parallel Workflows
**Use when**: Multiple independent tracks can proceed simultaneously

**Pattern**: Parallel tracks that merge at integration points
```
Backend Track:    Research → API Implementation → Testing
Frontend Track:   Research → UI Implementation → Testing
                            ↓
                  Integration Testing → Deployment
```

**Example**: Full-Stack Application
- **Backend Track**: API development with database
- **Frontend Track**: UI/UX with state management
- **Integration Point**: API contract (OpenAPI spec)
- **Merge**: End-to-end testing before deployment

### 3. Iterative Workflows
**Use when**: Refinement cycles are needed, feedback loops required

**Pattern**: Cycles with quality gates
```
Implement → Review → Refine → Test → [Pass? → Next Phase : Iterate]
```

**Example**: Code Quality Improvement
- Code analysis → Identify issues
- Refactoring → Apply improvements
- Testing → Verify correctness
- Review → Quality gate (pass/iterate)

## Common Workflow Templates

### API Development Workflow
**Objective**: Build production-ready RESTful API

**Agent Sequence**:
1. Research Assistant - Requirements analysis, tech stack research
2. Git Expert - Repository setup, branch strategy
3. Python Developer - API implementation, database models
4. Security Auditor - Authentication review, vulnerability scan
5. Test Architect - Test suite with >90% coverage
6. Documentation Expert - API docs, usage guides
7. Pipeline Engineer - CI/CD, automated deployment

**Critical Integration Points**:
- OpenAPI spec defines contract
- Database schema shared across implementation/deployment
- Security requirements inform authentication flow
- Test coverage gates deployment

### Infrastructure Setup Workflow
**Objective**: Production-ready cloud infrastructure

**Agent Sequence**:
1. Research Assistant - Architecture requirements, cloud provider evaluation
2. Git Expert - IaC repository setup
3. Infrastructure Specialist (Terraform) - Cloud resources, networking
4. Security Auditor - Security groups, IAM, secrets management
5. Container Expert (Docker) - Container optimization
6. Kubernetes Captain - Cluster setup, ingress, monitoring
7. Pipeline Engineer - Automated deployments, rollback strategy

**Critical Integration Points**:
- Terraform state shared across resources
- Security policies enforced at each layer
- Container images built in CI, deployed to K8s
- Monitoring integrated from day one

### Code Quality Review Workflow
**Objective**: Comprehensive code assessment and improvement

**Agent Sequence**:
1. Code Analysis Expert - Structure, architecture, patterns
2. Security Auditor - Vulnerability scanning, OWASP review
3. Refactoring Specialist - Code smells, improvement opportunities
4. Test Architect - Coverage analysis, test quality review
5. Code Reviewer - Final comprehensive review
6. Documentation Expert - Update docs based on changes

**Critical Integration Points**:
- Security findings inform refactoring priorities
- Test gaps identified guide test creation
- All improvements maintain backwards compatibility

### Research & Documentation Workflow
**Objective**: Technical research with knowledge preservation

**Agent Sequence**:
1. Research Assistant - External research, best practices
2. Code Analysis Expert - Internal codebase analysis
3. Knowledge Graph Integration - Pattern categorization (Graphiti Memory)
4. Documentation Expert - Technical docs, guides, tutorials
5. Communication Specialist - Summaries, announcements, training materials

**Critical Integration Points**:
- Research findings stored in knowledge graph
- Code patterns linked to recommendations
- Documentation references both internal/external sources
- Knowledge persists for future similar tasks

### UX Implementation Workflow
**Objective**: Bridge design decisions to production code with accessibility and usability

**Agent Sequence**:
1. **Service Design** - User journey mapping, service blueprints, high-level UX strategy
2. **UX Implementation** - Accessibility patterns (WCAG/ARIA), component usability, design tokens
3. **TypeScript/JavaScript Development** - Framework-specific implementation, state management
4. **Code Review** - Quality validation, accessibility audit
5. **Test Architecture** - Accessibility testing, visual regression, E2E tests
6. **Documentation** - Component usage guides, accessibility notes

**Critical Integration Points**:
- Service blueprints define user flows and interaction patterns
- UX specs include ARIA patterns, keyboard handling, focus management
- Design tokens shared as CSS custom properties
- Accessibility requirements become test criteria
- Component APIs defined before implementation

**Handoff Artifacts**:
- **Service Design → UX Implementation**: Journey maps, accessibility requirements, design system specs
- **UX Implementation → Development**: `@HANDOFF` markers with ARIA patterns, keyboard specs, responsive behavior
- **Development → Code Review**: Implemented components for accessibility validation
- **Code Review → Test Architecture**: Identified test scenarios, accessibility criteria

**Quality Gates**:
- WCAG 2.1 AA compliance verified before deployment
- Keyboard navigation tested manually
- Screen reader compatibility confirmed
- Color contrast ratios meet standards
- Touch targets meet minimum size (44x44px)

**Example Use Cases**:
- Building accessible form components
- Implementing modal dialogs with focus trap
- Creating responsive navigation patterns
- Adding dark mode with design tokens
- Improving existing component accessibility

## Coordination Principles

### 1. Clear Handoff Points
Each agent produces specific outputs for downstream agents:
- **Research** → Requirements doc, tech decisions
- **Implementation** → Working code, tests
- **Security** → Vulnerability report, remediation plan
- **Documentation** → User guides, API references

### 2. Shared Context Requirements
Define upfront what all agents need to know:
- **Tech Stack**: Languages, frameworks, tools
- **Quality Standards**: Coverage thresholds, security requirements
- **Integration Contracts**: APIs, data formats, interfaces
- **Success Criteria**: How to measure completion

### 3. Dependency Management
Track which agents depend on others:
```
research-assistant
  ↓
git-expert, python-developer (parallel)
  ↓
security-auditor
  ↓
test-architect
  ↓
docs-expert, pipeline-engineer (parallel)
```

### 4. Quality Gates
Define checkpoints before proceeding:
- All tests passing before documentation
- Security scan clean before deployment
- Code review approved before merge
- Coverage threshold met before release

## Workflow Customization

### Adapt Agent Sequences
- **Add specialists**: Insert domain experts where needed
- **Remove steps**: Skip unnecessary phases for simple projects
- **Parallel tracks**: Identify independent work streams

### Modify Integration Points
- **API-First**: Backend defines contract before frontend starts
- **Schema-First**: Database design before implementation
- **Test-First**: Write tests before implementation (TDD)

### Set Project-Specific Standards
- **Code style**: Black, Prettier, rustfmt, etc.
- **Git workflow**: Feature branches, PR requirements
- **Documentation**: Inline comments, external docs, API specs
- **Security**: Secrets management, authentication patterns

## Integration with Other Skills

- **Agent Context Management**: Coordinates context sharing between workflow phases
- **Knowledge Graph Patterns**: Stores workflow execution history for learning
- **Git Workflow**: Enforces branching and commit strategies during workflows
- **Test Architecture**: Ensures proper testing at each phase

## Examples

### Starting an API Project
```
User: "Build a RESTful API for user authentication with JWT tokens"

Claude applies this skill:
1. Recognizes multi-phase project (research, implementation, security, testing)
2. Selects API Development Workflow template
3. Plans agent sequence with proper dependencies
4. Coordinates handoffs between agents
5. Ensures security review before deployment
6. Verifies test coverage meets standards
```

### Refactoring Legacy Code
```
User: "Improve the quality and security of this legacy codebase"

Claude applies this skill:
1. Recognizes code quality workflow
2. Plans iterative approach (analyze → refactor → test → review)
3. Coordinates security audit with refactoring
4. Ensures tests maintain coverage during refactoring
5. Documents changes for future maintainers
```

## Best Practices

1. **Start with research** - Always understand requirements before implementation
2. **Parallel when possible** - Identify independent work streams
3. **Clear contracts** - Define interfaces between components upfront
4. **Quality gates** - Don't proceed with failing tests or security issues
5. **Document as you go** - Don't defer documentation to the end
6. **Learn from execution** - Store workflow results in knowledge graph

## Common Pitfalls

- ❌ Starting implementation before research/planning
- ❌ Running security audit after deployment
- ❌ Writing documentation after code is forgotten
- ❌ Deploying without test coverage
- ❌ Sequential workflows when parallel is possible
- ❌ Missing integration points between agents

## References

- Related Skills: `agent-context-management`, `knowledge-graph-patterns`
- Related Agents: All specialized agents (see `.claude/agents/`)
- Related Commands: `/git:smartcommit`, `/test:run`, `/github:process-issues`
