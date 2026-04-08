# Blueprint Documentation

Blueprint development structure for this project.

## Contents

- `manifest.json` — Blueprint configuration and task registry (v3.2.0)
- `work-orders/` — Detailed work order documents
- `ai_docs/` — AI-curated documentation

## Related Directories

- `docs/prds/` — Product Requirements Documents
- `docs/adrs/` — Architecture Decision Records
- `docs/prps/` — Product Requirement Prompts
- `.claude/rules/` — Generated and custom rules

## Commands

```bash
/blueprint:status          # Check configuration and task health
/blueprint:derive-prd      # Generate PRD from existing docs/codebase
/blueprint:derive-plans    # Derive docs from git history
/blueprint:derive-rules    # Generate rules from git patterns
/blueprint:generate-rules  # Generate rules from PRDs
/blueprint:adr-validate    # Validate ADR relationships
/blueprint:sync-ids        # Assign IDs to documents
/blueprint:execute         # Run next logical action
```
