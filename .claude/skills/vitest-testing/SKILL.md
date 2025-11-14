---
name: Vitest Testing
description: Modern TypeScript/JavaScript testing with Vitest. Fast unit and integration tests, native ESM support, Vite-powered HMR, and comprehensive mocking. Use for testing TS/JS projects.
allowed-tools: Bash, Read, Edit, Write, Grep, Glob, TodoWrite
---

# Vitest Testing

Expert knowledge for testing JavaScript/TypeScript projects using Vitest - a blazingly fast testing framework powered by Vite.

## Core Expertise

**Vitest Advantages**
- **Lightning-fast**: Powered by Vite's transformation pipeline with instant HMR
- **Native ESM**: First-class support for ES modules and TypeScript
- **Jest-compatible**: Drop-in replacement with familiar API
- **Watch mode**: Smart and instant re-runs on file changes
- **Component testing**: Built-in support for Vue, React, Svelte
- **Parallel execution**: Tests run in isolated worker threads

## Quick Start

### Installation

```bash
# Using Bun (recommended)
bun add -d vitest

# Using npm
npm install -D vitest

# Using pnpm
pnpm add -D vitest
```

### Basic Configuration

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    globals: true,              // Use global test APIs (describe, it, expect)
    environment: 'node',        // or 'jsdom', 'happy-dom' for browser APIs
    coverage: {
      provider: 'v8',           // or 'istanbul'
      reporter: ['text', 'json', 'html'],
      exclude: ['**/*.config.ts', '**/dist/**', '**/node_modules/**'],
    },
    include: ['**/*.{test,spec}.{js,ts,jsx,tsx}'],
    exclude: ['**/node_modules/**', '**/dist/**'],
  },
})
```

## Running Tests

### Command Line

```bash
# Run all tests
bun test
# or
vitest

# Run in watch mode (default)
vitest watch

# Run once (CI mode)
vitest run

# Run with coverage
vitest --coverage

# Run specific test file
vitest src/utils/math.test.ts

# Run tests matching pattern
vitest --grep="calculates sum"

# Run with UI (browser-based test explorer)
vitest --ui

# Verbose output
vitest --reporter=verbose

# Generate HTML coverage report
vitest --coverage --coverage.reporter=html
```

### Watch Mode Options

```bash
# Watch mode commands (press in terminal)
# a - run all tests
# f - run only failed tests
# u - update snapshots
# p - filter by filename
# t - filter by test name pattern
# q - quit
```

## Writing Tests

### Basic Test Structure

```typescript
import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import { add, subtract } from './math'

describe('Math utilities', () => {
  beforeEach(() => {
    // Setup before each test
  })

  afterEach(() => {
    // Cleanup after each test
  })

  it('adds two numbers correctly', () => {
    expect(add(2, 3)).toBe(5)
  })

  it('subtracts two numbers correctly', () => {
    expect(subtract(5, 3)).toBe(2)
  })
})
```

### Test Lifecycle Hooks

```typescript
import { describe, beforeAll, afterAll, beforeEach, afterEach } from 'vitest'

describe('User service', () => {
  // Runs once before all tests in this suite
  beforeAll(async () => {
    await setupDatabase()
  })

  // Runs once after all tests in this suite
  afterAll(async () => {
    await teardownDatabase()
  })

  // Runs before each test
  beforeEach(() => {
    resetMocks()
  })

  // Runs after each test
  afterEach(() => {
    cleanup()
  })
})
```

### Parametrized Tests

```typescript
import { describe, it, expect } from 'vitest'

describe.each([
  { input: 2, expected: 4 },
  { input: 3, expected: 9 },
  { input: 4, expected: 16 },
])('square function', ({ input, expected }) => {
  it(`squares ${input} to ${expected}`, () => {
    expect(square(input)).toBe(expected)
  })
})

// Alternative syntax
it.each([
  [1, 1],
  [2, 4],
  [3, 9],
])('squares %i to %i', (input, expected) => {
  expect(square(input)).toBe(expected)
})
```

### Test Filtering

```typescript
// Run only this test
it.only('this test will run', () => {
  expect(true).toBe(true)
})

// Skip this test
it.skip('this test will not run', () => {
  expect(false).toBe(true)
})

// Skip entire suite
describe.skip('skipped suite', () => {
  it('will not run', () => {})
})

// Conditional skip
it.skipIf(process.platform === 'win32')('Unix-only test', () => {
  // ...
})

// Run only on specific condition
it.runIf(process.env.CI)('Only in CI', () => {
  // ...
})

// Mark as todo
it.todo('implement this test later')
```

## Assertions

### Basic Matchers

```typescript
import { expect } from 'vitest'

// Equality
expect(value).toBe(expected)              // Same reference (===)
expect(value).toEqual(expected)           // Deep equality
expect(value).toStrictEqual(expected)     // Strict deep equality

// Truthiness
expect(value).toBeTruthy()
expect(value).toBeFalsy()
expect(value).toBeNull()
expect(value).toBeUndefined()
expect(value).toBeDefined()

// Numbers
expect(number).toBeGreaterThan(3)
expect(number).toBeGreaterThanOrEqual(3)
expect(number).toBeLessThan(5)
expect(number).toBeLessThanOrEqual(5)
expect(number).toBeCloseTo(0.3, 1)        // Floating point

// Strings
expect(string).toMatch(/pattern/)
expect(string).toContain('substring')

// Arrays and iterables
expect(array).toContain(item)
expect(array).toHaveLength(3)
expect(array).toMatchObject([{ id: 1 }])

// Objects
expect(object).toHaveProperty('key')
expect(object).toHaveProperty('key', value)
expect(object).toMatchObject({ a: 1 })

// Exceptions
expect(() => throwError()).toThrow()
expect(() => throwError()).toThrow(Error)
expect(() => throwError()).toThrow('error message')

// Promises
await expect(promise).resolves.toBe(value)
await expect(promise).rejects.toThrow()

// Snapshots
expect(component).toMatchSnapshot()
expect(data).toMatchInlineSnapshot(`"expected"`)
```

### Negation

```typescript
expect(value).not.toBe(other)
expect(array).not.toContain(item)
```

## Mocking

### Function Mocks

```typescript
import { vi, describe, it, expect } from 'vitest'

describe('Function mocking', () => {
  it('mocks a function', () => {
    const mockFn = vi.fn()
    mockFn('hello')

    expect(mockFn).toHaveBeenCalled()
    expect(mockFn).toHaveBeenCalledWith('hello')
    expect(mockFn).toHaveBeenCalledTimes(1)
  })

  it('mocks with return values', () => {
    const mockFn = vi.fn()
    mockFn.mockReturnValue(42)
    expect(mockFn()).toBe(42)

    // Different return values
    mockFn.mockReturnValueOnce(1)
    mockFn.mockReturnValueOnce(2)
    expect(mockFn()).toBe(1)
    expect(mockFn()).toBe(2)
  })

  it('mocks async functions', async () => {
    const mockFn = vi.fn()
    mockFn.mockResolvedValue('async result')

    const result = await mockFn()
    expect(result).toBe('async result')
  })

  it('mocks implementation', () => {
    const mockFn = vi.fn((x: number) => x * 2)
    expect(mockFn(5)).toBe(10)
  })
})
```

### Module Mocking

```typescript
import { vi, describe, it, expect, beforeEach } from 'vitest'

// Mock entire module
vi.mock('./api', () => ({
  fetchUser: vi.fn(() => ({ id: 1, name: 'Test User' })),
  createUser: vi.fn(),
}))

import { fetchUser, createUser } from './api'

describe('API calls', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('fetches user data', async () => {
    const user = await fetchUser(1)
    expect(user.name).toBe('Test User')
    expect(fetchUser).toHaveBeenCalledWith(1)
  })
})
```

### Partial Module Mocking

```typescript
import { vi } from 'vitest'

// Mock specific exports, keep others real
vi.mock('./utils', async (importOriginal) => {
  const actual = await importOriginal()
  return {
    ...actual,
    // Override only specific functions
    dangerousFunction: vi.fn(() => 'safe'),
  }
})
```

### Spy on Object Methods

```typescript
import { vi, describe, it, expect } from 'vitest'

describe('Spying', () => {
  it('spies on object methods', () => {
    const user = {
      name: 'John',
      getName: () => user.name,
    }

    const spy = vi.spyOn(user, 'getName')
    user.getName()

    expect(spy).toHaveBeenCalled()
    expect(spy).toHaveReturnedWith('John')

    spy.mockRestore() // Restore original implementation
  })
})
```

### Timers

```typescript
import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest'

describe('Timer mocking', () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('advances timers', () => {
    const callback = vi.fn()
    setTimeout(callback, 1000)

    vi.advanceTimersByTime(500)
    expect(callback).not.toHaveBeenCalled()

    vi.advanceTimersByTime(500)
    expect(callback).toHaveBeenCalledOnce()
  })

  it('runs all timers', () => {
    const callback = vi.fn()
    setTimeout(callback, 1000)

    vi.runAllTimers()
    expect(callback).toHaveBeenCalled()
  })

  it('mocks dates', () => {
    const date = new Date('2024-01-01')
    vi.setSystemTime(date)

    expect(Date.now()).toBe(date.getTime())
  })
})
```

## Async Testing

### Promises

```typescript
import { describe, it, expect } from 'vitest'

describe('Async tests', () => {
  it('waits for promises', async () => {
    const result = await fetchData()
    expect(result).toBe('data')
  })

  it('tests rejected promises', async () => {
    await expect(fetchData()).rejects.toThrow('Network error')
  })

  it('tests resolved promises', async () => {
    await expect(fetchData()).resolves.toBe('data')
  })
})
```

### Concurrent Tests

```typescript
import { describe, it } from 'vitest'

// Run tests in parallel
describe.concurrent('Parallel tests', () => {
  it('test 1', async () => {
    await slowOperation1()
  })

  it('test 2', async () => {
    await slowOperation2()
  })
})

// Control concurrency
describe.concurrent('Limited concurrency', { concurrent: 2 }, () => {
  // Max 2 tests run in parallel
})
```

## Coverage

### Configuration

```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',  // Fast, native V8 coverage
      // provider: 'istanbul',  // More accurate but slower

      reporter: ['text', 'json', 'html', 'lcov'],

      // Coverage thresholds
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 80,
        statements: 80,
      },

      // Exclude patterns
      exclude: [
        'node_modules/',
        'dist/',
        '**/*.config.ts',
        '**/*.d.ts',
        '**/types/**',
        '**/__tests__/**',
      ],

      // Include patterns
      include: ['src/**/*.ts', 'src/**/*.tsx'],
    },
  },
})
```

### Running Coverage

```bash
# Generate coverage report
vitest --coverage

# Watch mode with coverage
vitest --coverage --watch

# HTML report (opens in browser)
vitest --coverage --coverage.reporter=html
open coverage/index.html

# Check against thresholds
vitest --coverage --coverage.thresholds.lines=90
```

## Integration Testing

### API Testing

```typescript
import { describe, it, expect, beforeAll, afterAll } from 'vitest'
import request from 'supertest'
import { app } from './app'
import { setupTestDatabase, teardownTestDatabase } from './test-utils'

describe('API endpoints', () => {
  beforeAll(async () => {
    await setupTestDatabase()
  })

  afterAll(async () => {
    await teardownTestDatabase()
  })

  it('creates a user', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ name: 'John', email: 'john@example.com' })
      .expect(201)

    expect(response.body).toMatchObject({
      id: expect.any(Number),
      name: 'John',
      email: 'john@example.com',
    })
  })

  it('handles validation errors', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ name: '' })
      .expect(400)

    expect(response.body.error).toBeDefined()
  })
})
```

### Database Testing

```typescript
import { describe, it, expect, beforeEach } from 'vitest'
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

describe('User repository', () => {
  beforeEach(async () => {
    await prisma.user.deleteMany()
  })

  it('creates and retrieves a user', async () => {
    const created = await prisma.user.create({
      data: { name: 'John', email: 'john@example.com' },
    })

    const retrieved = await prisma.user.findUnique({
      where: { id: created.id },
    })

    expect(retrieved).toEqual(created)
  })
})
```

## Best Practices

**Test Organization**
- One test file per source file: `math.ts` → `math.test.ts`
- Group related tests with `describe()` blocks
- Use descriptive test names that explain behavior
- Keep tests focused and atomic

**Mocking Strategy**
- Mock external dependencies (APIs, databases)
- Keep real implementations for internal utilities
- Avoid overmocking - test real integration when possible
- Clear mocks between tests with `beforeEach()`

**Performance**
- Use `concurrent` tests for independent async tests
- Avoid unnecessary `beforeEach()` setup
- Share expensive fixtures with `beforeAll()`
- Use watch mode during development

**Coverage**
- Aim for 80%+ coverage but don't chase 100%
- Focus on critical business logic
- Exclude generated files and type definitions
- Use coverage to find untested code paths

**Common Patterns**

```typescript
// Test data builders
function createMockUser(overrides = {}) {
  return {
    id: 1,
    name: 'Test User',
    email: 'test@example.com',
    ...overrides,
  }
}

// Custom matchers
expect.extend({
  toBeWithinRange(received, floor, ceiling) {
    const pass = received >= floor && received <= ceiling
    return {
      pass,
      message: () => `expected ${received} to be within ${floor}-${ceiling}`,
    }
  },
})

// Test utilities
export async function waitFor(callback: () => void, timeout = 1000) {
  const start = Date.now()
  while (Date.now() - start < timeout) {
    try {
      callback()
      return
    } catch {
      await new Promise(resolve => setTimeout(resolve, 50))
    }
  }
  throw new Error('Timeout waiting for condition')
}
```

## Troubleshooting

**Tests not running in watch mode**
```bash
# Ensure you're in the project root
vitest

# Check for config file
ls vitest.config.ts
```

**Module resolution errors**
```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
})
```

**Coverage not collecting**
```bash
# Install coverage provider
bun add -d @vitest/coverage-v8

# Or use istanbul
bun add -d @vitest/coverage-istanbul
```

**Slow tests**
```bash
# Find slow tests
vitest --reporter=verbose

# Run specific slow tests
vitest --grep="slow test name"
```

## See Also

- `nodejs-development` - Project setup and tooling
- `playwright-testing` - E2E testing with Playwright
- `test-quality-analysis` - Detecting test smells and overmocking

## References

- Official docs: https://vitest.dev/
- API reference: https://vitest.dev/api/
- Configuration: https://vitest.dev/config/
