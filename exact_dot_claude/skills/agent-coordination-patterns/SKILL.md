---
name: agent-coordination-patterns
description: |
  Coordinate multi-agent workflows: sequential, parallel, and iterative patterns.
  Defines agent handoffs, dependencies, communication protocols, and integration.
  Use when designing multi-agent workflows, coordinating agent handoffs,
  planning agent dependencies, or building complex agent pipelines.
---

# Agent Coordination Patterns

## Description

Coordination patterns for sequential, parallel, and iterative agent workflows. Defines how agents work together, communicate findings, and maintain context across handoffs in multi-agent systems.

## When to Use

Automatically apply this skill when:
- Designing multi-agent workflows
- Coordinating agent handoffs
- Planning agent dependencies
- Integrating agent outputs
- Building complex workflows
- Optimizing agent collaboration

## Core Principle: Hybrid Context Sharing

Two complementary layers work together:

**1. Transparency Layer** (File-Based)
- Human-inspectable files
- Real-time progress visibility
- Easy debugging and inspection
- Clear agent coordination

**2. Intelligence Layer** (Knowledge Graph)
- Historical learning
- Pattern recognition
- Cross-session persistence
- Audit trails

## Agent Integration Protocol

### Phase 1: Pre-Execution Context Reading

Before starting work, agents MUST:

1. **Read workflow context** → Understand overall objective
2. **Check agent queue** → Know dependencies and position
3. **Review shared data** → Get requirements and standards
4. **Read dependency outputs** → Build on previous work

**Example Flow**:
```
User delegates to python-developer:

1. Read current-workflow.md → "Building REST API"
2. Read agent-queue.md → "research-assistant completed"
3. Read inter-agent-context.json → "Tech: FastAPI + PostgreSQL"
4. Read research-assistant-output.md → "Requirements defined"
5. Begin implementation with full context
```

### Phase 2: Progress Reporting During Execution

Continuously communicate state:

- Update progress file every 5-10 minutes
- Report current activity clearly
- List completed steps
- Note any blockers immediately
- Estimate remaining time

### Phase 3: Post-Execution Output Writing

Produce standardized results:

- Document all accomplishments
- Record technical decisions
- List created artifacts
- Note known issues
- Provide handoff guidance

## Coordination Patterns

### Sequential Coordination

Agents work one after another, each building on previous work.

**Pattern Structure**:
```
Agent A completes → Writes output
  ↓
Agent B reads A's output → Starts work → Writes output
  ↓
Agent C reads A's and B's outputs → Starts work
```

**When to use**:
- Clear dependencies exist
- Each step requires previous completion
- Linear workflow progression

**Example Workflow**:
```
Research Assistant (30 min)
  ↓ (passes requirements)
Python Developer (90 min)
  ↓ (passes implementation)
Test Architect (45 min)
  ↓ (passes test suite)
Documentation Writer (30 min)
```

**Best Practices**:
- Complete handoff notes are critical
- Each agent validates previous work
- Include "next agent needs" section
- Document all assumptions made

### Parallel Coordination

Multiple agents work simultaneously on independent tasks.

**Pattern Structure**:
```
         ┌→ Agent A → Output A
Start →  ├→ Agent B → Output B  → Integration Agent
         └→ Agent C → Output C
```

**When to use**:
- Independent work streams
- No direct dependencies
- Can merge results later
- Want faster completion

**Example Workflow**:
```
Requirements Defined
    ├→ Backend Developer (API)
    ├→ Frontend Developer (UI)
    └→ Database Architect (Schema)
         ↓
    Integration Tester (Verify all parts work together)
```

**Best Practices**:
- Define clear interfaces upfront
- Use shared contracts (API specs)
- Regular sync points
- Integration agent validates compatibility

**Shared Contract Example**:
```json
{
  "api_contract": {
    "/api/users": {
      "GET": "returns user list",
      "POST": "creates user"
    }
  },
  "data_models": {
    "User": {
      "id": "string",
      "name": "string",
      "email": "string"
    }
  }
}
```

### Iterative Coordination

Agent revisits work based on feedback from other agents.

**Pattern Structure**:
```
Agent A → Agent B (reviews) → Issues found
  ↑                               ↓
  ←───────── Feedback ────────────↓
```

**When to use**:
- Quality improvement cycles
- Refinement needed
- Review and feedback loops
- Progressive enhancement

**Example Workflow**:
```
Developer → Code Review → Issues Found
    ↑                         ↓
    ←── Fix Issues ──────────↓

Security Auditor → Vulnerabilities Found
    ↑                         ↓
Developer ←── Apply Fixes ───↓
```

**Best Practices**:
- Clear feedback format
- Specific actionable items
- Track iteration count
- Define completion criteria

**Feedback Format**:
```markdown
## Review Feedback

### Critical Issues (Must Fix)
1. SQL injection vulnerability in `/api/users` line 45
2. Missing authentication on DELETE endpoint

### Improvements (Should Fix)
1. Add input validation for email format
2. Implement rate limiting

### Suggestions (Could Improve)
1. Consider caching for performance
2. Add more descriptive error messages
```

### Hybrid Coordination

Combines multiple patterns for complex workflows.

**Example Structure**:
```
Sequential Start:
  Research → Architecture Design
           ↓
Parallel Development:
  ├→ Backend Team
  ├→ Frontend Team
  └→ QA Test Planning
           ↓
Sequential Integration:
  Integration → Testing
           ↓
Iterative Refinement:
  Review ↔ Fixes
```

**When to use**:
- Complex projects
- Multiple teams
- Different phases need different patterns
- Optimization opportunities

## Coordination Rules

### Dependency Management

**Hard Dependencies** (Must Complete First):
```json
{
  "agent": "test-architect",
  "depends_on": ["python-developer"],
  "reason": "Cannot test code that doesn't exist"
}
```

**Soft Dependencies** (Preferred Order):
```json
{
  "agent": "documentation-writer",
  "prefers_after": ["test-architect"],
  "reason": "Better docs with test examples"
}
```

### Communication Protocols

**Status Broadcasting**:
- STARTING: Beginning work
- IN_PROGRESS: Active work (% complete)
- BLOCKED: Cannot continue
- COMPLETED: Finished successfully
- FAILED: Could not complete

**Handoff Requirements**:
- Summary of work done
- Decisions made
- Artifacts created
- Known issues
- Next steps guidance

### Conflict Resolution

**When agents disagree**:
1. Document both perspectives
2. Escalate to user if critical
3. Use precedence rules
4. Security > Functionality > Performance

**Precedence Rules**:
```
Security Auditor > All Others (security issues)
Architect > Developers (design decisions)
Senior > Junior (experience hierarchy)
Later > Earlier (recent context)
```

## Best Practices

### 1. Clear Communication
- Explicit handoff notes
- Document all assumptions
- State dependencies clearly
- Update progress frequently

### 2. Robust Error Handling
- Check for previous failures
- Validate inputs exist
- Handle missing dependencies
- Report blockers immediately

### 3. Maintain Context
- Read all relevant outputs
- Preserve decision history
- Update shared context
- Don't duplicate work

### 4. Quality Gates
- Validate before handoff
- Test integration points
- Review critical paths
- Ensure completeness

## Common Pitfalls

- ❌ Starting without reading context
- ❌ Not updating progress during execution
- ❌ Vague or incomplete handoff notes
- ❌ Missing dependency outputs
- ❌ Parallel work without contracts
- ❌ No integration validation
- ❌ Infinite iteration loops

## Examples

### Example 1: Sequential API Development

```python
# Workflow: Build User Authentication API

# Step 1: Research Assistant
read_context()
output = {
    "requirements": ["JWT auth", "2FA support"],
    "constraints": ["GDPR compliant", "Sub-100ms response"],
    "decisions": {"framework": "FastAPI"}
}
write_output("research-assistant-output.md", output)

# Step 2: Python Developer
context = read_context()
research = read_output("research-assistant-output.md")
implement_based_on(research)
output = {
    "implemented": ["/auth/login", "/auth/logout"],
    "tests": "90% coverage",
    "next_agent_needs": "Security review of auth.py"
}
write_output("python-developer-output.md", output)

# Step 3: Security Auditor
implementation = read_output("python-developer-output.md")
audit_results = security_review(implementation)
write_output("security-auditor-output.md", audit_results)
```

### Example 2: Parallel Frontend/Backend

```python
# Shared contract defined first
contract = {
    "api": {
        "/api/products": {
            "GET": "returns product list",
            "POST": "creates product"
        }
    },
    "models": {
        "Product": {
            "id": "string",
            "name": "string",
            "price": "number"
        }
    }
}

# Parallel execution
parallel(
    backend_developer(contract),  # Implements API
    frontend_developer(contract),  # Implements UI
)

# Integration validation
integration_tester(
    backend_output,
    frontend_output,
    contract
)
```

### Example 3: Iterative Code Review

```python
iteration = 1
max_iterations = 3

while iteration <= max_iterations:
    # Developer implements/fixes
    if iteration == 1:
        implementation = develop_feature()
    else:
        implementation = apply_feedback(review_feedback)

    # Reviewer checks
    review_feedback = code_review(implementation)

    if review_feedback["critical_issues"] == []:
        break

    iteration += 1

write_output("final-implementation.md", implementation)
```

### Example 4: UX Implementation Handoff

```python
# Workflow: Accessible Modal Component

# Step 1: Service Design creates UX strategy
service_design_output = {
    "component": "ConfirmationModal",
    "user_journey": "User clicks delete → Modal confirms → Action executes",
    "accessibility_requirements": [
        "WCAG 2.1 AA compliance",
        "Keyboard navigable",
        "Screen reader compatible"
    ],
    "interaction_pattern": "Modal dialog with focus trap"
}
write_output("service-design-output.md", service_design_output)

# Step 2: UX Implementation creates specifications
ux_specs = {
    "aria_pattern": {
        "role": "dialog",
        "aria-modal": "true",
        "aria-labelledby": "modal-title"
    },
    "keyboard_handling": {
        "Tab": "Cycle through focusable elements",
        "Escape": "Close modal",
        "Enter": "Activate focused button"
    },
    "focus_management": {
        "on_open": "Focus first focusable element",
        "on_close": "Return focus to trigger element",
        "trap": "Keep focus within modal"
    }
}

# Create @HANDOFF marker in code for typescript-development
handoff_marker = """
// @HANDOFF(typescript-development) {
//   type: "component-implementation",
//   context: "Modal dialog for confirmation actions",
//   ux-specs: {
//     aria: "role=dialog, aria-modal=true, aria-labelledby",
//     focus: "trap focus, return on close, Escape to dismiss",
//     animation: "fade-in 150ms ease-out"
//   },
//   tests: [
//     "focus moves to first element on open",
//     "Escape key closes modal",
//     "focus returns to trigger on close",
//     "Tab cycles within modal"
//   ],
//   refs: ["src/components/Dialog/Dialog.tsx"]
// }
"""
write_output("ux-implementation-output.md", ux_specs)

# Step 3: TypeScript development implements component
# Reads UX specs and implements accessible React component
context = read_output("ux-implementation-output.md")
implementation = implement_component(context)

# Step 4: Code review validates accessibility
accessibility_review = {
    "wcag_compliance": "AA",
    "aria_audit": "PASS",
    "keyboard_test": "PASS",
    "issues": []
}
```

**Handoff Marker Pattern**:

The `@HANDOFF` marker in code creates an asynchronous communication channel:

```typescript
// In src/components/Modal/Modal.tsx

// @HANDOFF(ux-implementation) {
//   type: "form-validation",
//   context: "Delete confirmation with validation",
//   needs: [
//     "Error announcement pattern for screen readers",
//     "Focus management after validation failure"
//   ],
//   priority: "blocking"
// }
function ConfirmationModal({ onConfirm, onCancel }: Props) {
  // Implementation with UX placeholder
  const handleValidationError = (error: string) => {
    // @UX-PLACEHOLDER: accessible error announcement
    setError(error);
  };
}
```

After UX agent processes:

```typescript
// @HANDOFF-COMPLETE(ux-implementation) {
//   resolved: "2024-01-15",
//   implemented: [
//     "ARIA live region for errors",
//     "Focus moves to error summary",
//     "Clear button gets focus after error"
//   ]
// }
function ConfirmationModal({ onConfirm, onCancel }: Props) {
  const handleValidationError = (error: string) => {
    setError(error);
    // Announce error to screen readers
    announceToScreenReader(error, 'assertive');
    // Move focus to error summary
    errorSummaryRef.current?.focus();
  };
}
```

## Integration with Other Skills

- **agent-file-coordination**: Uses file structures for coordination
- **graphiti-learning-workflows**: Learn optimal coordination patterns
- **graphiti-episode-storage**: Store successful patterns
- **multi-agent-workflows**: Higher-level workflow orchestration

## References

- Related Skills: `agent-file-coordination`, `multi-agent-workflows`
- Design Patterns: Sequential, Parallel, Iterative, Hybrid
- Replaces: `agent-context-management` (coordination sections)
