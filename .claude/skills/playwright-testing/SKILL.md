---
name: Playwright Testing
description: End-to-end testing with Playwright. Cross-browser testing, visual regression, API testing, and component testing. Use for E2E tests in TypeScript/JavaScript and Python projects.
allowed-tools: Bash, Read, Edit, Write, Grep, Glob, TodoWrite
---

# Playwright Testing

Expert knowledge for end-to-end testing with Playwright - a modern cross-browser testing framework with powerful debugging and reliable automation.

## Core Expertise

**Playwright Advantages**
- **Cross-browser**: Chromium, Firefox, WebKit (Safari) support
- **Auto-wait**: Built-in smart waiting, no flaky tests
- **Powerful selectors**: CSS, text, role-based selectors
- **Network control**: Mock APIs, intercept requests
- **Visual testing**: Screenshots, videos, trace viewer
- **Parallel execution**: Fast test runs across browsers
- **TypeScript-first**: Excellent type safety and autocomplete

## Quick Start

### Installation (TypeScript/JavaScript)

```bash
# Using Bun
bun add -d @playwright/test

# Using npm
npm init playwright@latest

# Using pnpm
pnpm create playwright
```

### Installation (Python)

```bash
# Using uv
uv add --dev pytest-playwright
uv run playwright install

# Using pip
pip install pytest-playwright
playwright install
```

### Basic Configuration (TypeScript)

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',

  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    // Mobile browsers
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] },
    },
  ],

  webServer: {
    command: 'bun run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
})
```

### Basic Configuration (Python)

```python
# conftest.py
import pytest

@pytest.fixture(scope="session")
def browser_context_args(browser_context_args):
    return {
        **browser_context_args,
        "viewport": {"width": 1920, "height": 1080},
        "base_url": "http://localhost:3000",
    }
```

## Running Tests

### TypeScript Commands

```bash
# Run all tests
npx playwright test

# Run in headed mode (see browser)
npx playwright test --headed

# Run specific test file
npx playwright test tests/login.spec.ts

# Run tests matching pattern
npx playwright test --grep="login"

# Run in debug mode
npx playwright test --debug

# Run with UI mode (interactive)
npx playwright test --ui

# Run specific browser
npx playwright test --project=chromium
npx playwright test --project=firefox

# Generate test report
npx playwright show-report

# Open trace viewer for failed tests
npx playwright show-trace trace.zip
```

### Python Commands

```bash
# Run all tests
uv run pytest

# Run with headed browser
uv run pytest --headed

# Run specific test
uv run pytest tests/test_login.py

# Run with specific browser
uv run pytest --browser chromium
uv run pytest --browser firefox
uv run pytest --browser webkit

# Slow motion (for debugging)
uv run pytest --slowmo 1000

# Generate video
uv run pytest --video on
```

## Writing Tests (TypeScript)

### Basic Test Structure

```typescript
import { test, expect } from '@playwright/test'

test.describe('Login flow', () => {
  test('successful login', async ({ page }) => {
    await page.goto('/')
    await page.getByRole('link', { name: 'Login' }).click()
    await page.getByLabel('Email').fill('user@example.com')
    await page.getByLabel('Password').fill('password123')
    await page.getByRole('button', { name: 'Sign in' }).click()

    await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible()
  })

  test('shows error for invalid credentials', async ({ page }) => {
    await page.goto('/login')
    await page.getByLabel('Email').fill('wrong@example.com')
    await page.getByLabel('Password').fill('wrongpassword')
    await page.getByRole('button', { name: 'Sign in' }).click()

    await expect(page.getByText('Invalid credentials')).toBeVisible()
  })
})
```

### Test Hooks

```typescript
import { test, expect } from '@playwright/test'

test.describe('User management', () => {
  test.beforeAll(async () => {
    // Setup database
  })

  test.beforeEach(async ({ page }) => {
    await page.goto('/admin/users')
    // Setup per test
  })

  test.afterEach(async ({ page }) => {
    // Cleanup per test
  })

  test.afterAll(async () => {
    // Teardown database
  })
})
```

## Writing Tests (Python)

### Basic Test Structure

```python
import pytest
from playwright.sync_api import Page, expect

def test_successful_login(page: Page):
    page.goto("/")
    page.get_by_role("link", name="Login").click()
    page.get_by_label("Email").fill("user@example.com")
    page.get_by_label("Password").fill("password123")
    page.get_by_role("button", name="Sign in").click()

    expect(page.get_by_role("heading", name="Dashboard")).to_be_visible()

def test_invalid_credentials(page: Page):
    page.goto("/login")
    page.get_by_label("Email").fill("wrong@example.com")
    page.get_by_label("Password").fill("wrongpassword")
    page.get_by_role("button", name="Sign in").click()

    expect(page.get_by_text("Invalid credentials")).to_be_visible()
```

### Test Fixtures (Python)

```python
import pytest
from playwright.sync_api import Page

@pytest.fixture
def authenticated_page(page: Page):
    page.goto("/login")
    page.get_by_label("Email").fill("user@example.com")
    page.get_by_label("Password").fill("password123")
    page.get_by_role("button", name="Sign in").click()
    return page

def test_dashboard_access(authenticated_page: Page):
    authenticated_page.goto("/dashboard")
    expect(authenticated_page.get_by_role("heading", name="Dashboard")).to_be_visible()
```

## Selectors

### Role-Based Selectors (Recommended)

```typescript
// Most reliable - based on ARIA roles
await page.getByRole('button', { name: 'Submit' })
await page.getByRole('link', { name: 'Home' })
await page.getByRole('textbox', { name: 'Email' })
await page.getByRole('checkbox', { name: 'Remember me' })
await page.getByRole('heading', { name: 'Welcome', level: 1 })
```

### Text Selectors

```typescript
// Find by exact text
await page.getByText('Hello World')

// Find by partial text
await page.getByText('Hello', { exact: false })

// Case insensitive
await page.getByText(/hello world/i)
```

### Label Selectors

```typescript
// Find inputs by label
await page.getByLabel('Email')
await page.getByLabel('Password')
await page.getByLabel(/email/i)
```

### Placeholder and Alt Text

```typescript
await page.getByPlaceholder('Enter email')
await page.getByAltText('Company logo')
```

### Test ID (Fallback)

```typescript
// In HTML: <div data-testid="submit-button">
await page.getByTestId('submit-button')
```

### CSS Selectors (Use Sparingly)

```typescript
await page.locator('.btn-primary')
await page.locator('#login-form')
await page.locator('button.submit')
```

### Combining Selectors

```typescript
// Chaining
await page.getByRole('navigation').getByRole('link', { name: 'Home' })

// Filtering
await page.getByRole('listitem').filter({ hasText: 'Product 1' })

// First/Last/Nth
await page.getByRole('button').first()
await page.getByRole('button').last()
await page.getByRole('button').nth(2)
```

## Assertions

### Visibility Assertions

```typescript
await expect(page.getByText('Success')).toBeVisible()
await expect(page.getByText('Loading')).toBeHidden()
await expect(page.getByRole('button')).toBeEnabled()
await expect(page.getByRole('button')).toBeDisabled()
```

### Text Assertions

```typescript
await expect(page.getByRole('heading')).toHaveText('Welcome')
await expect(page.getByRole('heading')).toContainText('Welcome')
await expect(page.getByRole('alert')).toHaveText(/error/i)
```

### Attribute Assertions

```typescript
await expect(page.getByRole('link')).toHaveAttribute('href', '/home')
await expect(page.getByRole('img')).toHaveAttribute('alt', 'Logo')
await expect(page.getByRole('button')).toHaveClass('btn-primary')
```

### Value Assertions

```typescript
await expect(page.getByLabel('Email')).toHaveValue('user@example.com')
await expect(page.getByLabel('Count')).toHaveValue('5')
```

### URL Assertions

```typescript
await expect(page).toHaveURL('/dashboard')
await expect(page).toHaveURL(/\/dashboard/)
await expect(page).toHaveTitle('Dashboard')
```

### Count Assertions

```typescript
await expect(page.getByRole('listitem')).toHaveCount(5)
```

## Actions

### Clicking

```typescript
// Basic click
await page.getByRole('button', { name: 'Submit' }).click()

// Double click
await page.getByText('File').dblclick()

// Right click
await page.getByText('Item').click({ button: 'right' })

// Click with modifiers
await page.getByRole('link').click({ modifiers: ['Control'] })

// Force click (bypass visibility checks)
await page.getByRole('button').click({ force: true })
```

### Typing

```typescript
// Fill (clears then types)
await page.getByLabel('Email').fill('user@example.com')

// Type (appends)
await page.getByLabel('Search').type('query')

// Press keys
await page.getByLabel('Search').press('Enter')
await page.keyboard.press('Control+A')

// Type slowly (for animations)
await page.getByLabel('Search').type('query', { delay: 100 })
```

### Selecting

```typescript
// Select by value
await page.getByLabel('Country').selectOption('us')

// Select by label
await page.getByLabel('Country').selectOption({ label: 'United States' })

// Select multiple
await page.locator('select[multiple]').selectOption(['us', 'uk', 'ca'])
```

### File Upload

```typescript
// Single file
await page.getByLabel('Upload').setInputFiles('path/to/file.pdf')

// Multiple files
await page.getByLabel('Upload').setInputFiles([
  'file1.pdf',
  'file2.pdf',
])

// Remove files
await page.getByLabel('Upload').setInputFiles([])
```

### Drag and Drop

```typescript
await page.getByText('Item').dragTo(page.getByText('Target'))
```

## Network Mocking

### Intercept API Requests

```typescript
import { test, expect } from '@playwright/test'

test('mocks API response', async ({ page }) => {
  // Mock API endpoint
  await page.route('**/api/users', async route => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify([
        { id: 1, name: 'Test User' },
      ]),
    })
  })

  await page.goto('/users')
  await expect(page.getByText('Test User')).toBeVisible()
})
```

### Intercept and Modify

```typescript
test('modifies API response', async ({ page }) => {
  await page.route('**/api/config', async route => {
    const response = await route.fetch()
    const json = await response.json()
    json.feature_flag = true
    await route.fulfill({ json })
  })

  await page.goto('/')
})
```

### Wait for Requests

```typescript
test('waits for API call', async ({ page }) => {
  await page.goto('/')

  // Wait for specific request
  const response = await page.waitForResponse('**/api/users')
  expect(response.status()).toBe(200)

  // Wait for multiple requests
  const [response1, response2] = await Promise.all([
    page.waitForResponse('**/api/users'),
    page.waitForResponse('**/api/posts'),
    page.getByRole('button', { name: 'Load' }).click(),
  ])
})
```

## Visual Testing

### Screenshots

```typescript
import { test } from '@playwright/test'

test('captures screenshot', async ({ page }) => {
  await page.goto('/')

  // Full page screenshot
  await page.screenshot({ path: 'screenshot.png', fullPage: true })

  // Element screenshot
  await page.getByRole('navigation').screenshot({ path: 'nav.png' })

  // Compare screenshot
  await expect(page).toHaveScreenshot('homepage.png')
})
```

### Video Recording

```typescript
// In playwright.config.ts
use: {
  video: 'on',  // or 'retain-on-failure', 'off'
  videoSize: { width: 1280, height: 720 }
}
```

### Trace Viewer

```typescript
// In playwright.config.ts
use: {
  trace: 'on-first-retry',  // or 'on', 'off', 'retain-on-failure'
}
```

```bash
# View trace
npx playwright show-trace trace.zip
```

## Authentication & State

### Save Authentication State

```typescript
import { test as setup } from '@playwright/test'

setup('authenticate', async ({ page }) => {
  await page.goto('/login')
  await page.getByLabel('Email').fill('user@example.com')
  await page.getByLabel('Password').fill('password123')
  await page.getByRole('button', { name: 'Sign in' }).click()

  // Save storage state
  await page.context().storageState({ path: 'auth.json' })
})
```

### Reuse Authentication State

```typescript
// playwright.config.ts
export default defineConfig({
  projects: [
    {
      name: 'setup',
      testMatch: /auth\.setup\.ts/,
    },
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        storageState: 'auth.json',
      },
      dependencies: ['setup'],
    },
  ],
})
```

## Best Practices

**Selector Strategy**
1. **Prefer role-based selectors**: `getByRole('button', { name: 'Submit' })`
2. **Use labels for inputs**: `getByLabel('Email')`
3. **Text for content**: `getByText('Welcome')`
4. **Test IDs as fallback**: `getByTestId('submit-btn')`
5. **Avoid CSS selectors**: They break easily with styling changes

**Auto-Waiting**
- Playwright automatically waits for elements
- No need for manual `sleep()` or `waitFor()`
- Trust the built-in waiting mechanisms

**Isolation**
- Each test gets a fresh browser context
- No state pollution between tests
- Clean cookies, storage, cache per test

**Debugging**
```bash
# Debug mode (step through tests)
npx playwright test --debug

# Headed mode (see browser)
npx playwright test --headed --slowmo 1000

# UI mode (interactive explorer)
npx playwright test --ui

# Trace viewer (time-travel debugging)
npx playwright show-trace trace.zip
```

**Performance**
- Run tests in parallel (default)
- Use `fullyParallel: true` in config
- Limit workers in CI: `workers: 1`
- Reuse browser contexts when possible

**Flaky Tests**
- Use auto-waiting, avoid manual waits
- Use specific selectors, avoid brittle CSS
- Mock network requests for consistency
- Set proper timeouts for slow operations

**Test Data**
- Reset database state before tests
- Use unique test data per test
- Clean up after tests
- Mock external dependencies

## Common Patterns

### Page Object Model

```typescript
// pages/LoginPage.ts
import { Page, Locator } from '@playwright/test'

export class LoginPage {
  readonly page: Page
  readonly emailInput: Locator
  readonly passwordInput: Locator
  readonly submitButton: Locator

  constructor(page: Page) {
    this.page = page
    this.emailInput = page.getByLabel('Email')
    this.passwordInput = page.getByLabel('Password')
    this.submitButton = page.getByRole('button', { name: 'Sign in' })
  }

  async goto() {
    await this.page.goto('/login')
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email)
    await this.passwordInput.fill(password)
    await this.submitButton.click()
  }
}

// Usage in test
import { test, expect } from '@playwright/test'
import { LoginPage } from './pages/LoginPage'

test('login flow', async ({ page }) => {
  const loginPage = new LoginPage(page)
  await loginPage.goto()
  await loginPage.login('user@example.com', 'password123')
  await expect(page).toHaveURL('/dashboard')
})
```

### API Testing

```typescript
import { test, expect } from '@playwright/test'

test('API test', async ({ request }) => {
  const response = await request.post('/api/users', {
    data: {
      name: 'John Doe',
      email: 'john@example.com',
    },
  })

  expect(response.ok()).toBeTruthy()
  expect(response.status()).toBe(201)

  const json = await response.json()
  expect(json.id).toBeDefined()
  expect(json.name).toBe('John Doe')
})
```

### Mobile Testing

```typescript
// playwright.config.ts
import { devices } from '@playwright/test'

export default defineConfig({
  projects: [
    {
      name: 'iPhone 13',
      use: { ...devices['iPhone 13'] },
    },
    {
      name: 'iPad Pro',
      use: { ...devices['iPad Pro'] },
    },
  ],
})
```

## Troubleshooting

**Element not found**
```typescript
// Wait for element explicitly
await page.getByRole('button').waitFor()

// Check if element exists
const isVisible = await page.getByRole('button').isVisible()
```

**Timeout errors**
```typescript
// Increase timeout for specific action
await page.getByRole('button').click({ timeout: 10000 })

// Global timeout in config
use: {
  actionTimeout: 10000,
  navigationTimeout: 30000,
}
```

**Flaky tests**
```typescript
// Use auto-retry assertions
await expect(page.getByText('Success')).toBeVisible({ timeout: 5000 })

// Retry failed tests
retries: process.env.CI ? 2 : 0
```

## See Also

- `vitest-testing` - Unit and integration testing
- `test-quality-analysis` - Detecting test smells
- `nodejs-development` - TypeScript project setup
- `python-testing` - Python pytest integration

## References

- Official docs: https://playwright.dev/
- API reference: https://playwright.dev/docs/api/class-playwright
- Best practices: https://playwright.dev/docs/best-practices
