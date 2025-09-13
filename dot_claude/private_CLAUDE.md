# CLAUDE.md - High-Level Design & Delegation

This document outlines the high-level design principles and operational mandates. The core philosophy is to maintain a strategic focus and delegate all specific implementation tasks to specialized subagents.

## Core Principles

- **Research documentation**: Before implementation, make sure to research documentation about the parts it will touch
- **PRD-First Development**: Every new feature or significant change MUST have a Product Requirements Document (PRD) created before any implementation begins
- **Don't Reinvent the Wheel**: Leverage existing, proven solutions before creating custom implementations
- **Test-Driven Development (TDD)**: Make sure strict RED, GREEN, REFACTOR workflow is followed to ensure robust and maintainable code
- **Commit early and often**: Make sure commits are made often. It's important to keep track of small changes during work.
