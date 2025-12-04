---
name: ESLint Configuration
description: |
  ESLint 9.x flat config system for JavaScript and TypeScript linting.
  Migration from legacy .eslintrc, TypeScript integration, popular plugins (react-hooks, import).
  Use when configuring ESLint for complex projects, needing specialized plugins, or maintaining
  ESLint-based workflows. For simpler needs, consider Biome.
allowed-tools: Glob, Grep, Read, Bash, Edit, Write, TodoWrite, WebFetch, WebSearch, BashOutput, KillShell
---

# ESLint Configuration

ESLint is the industry-standard linter for JavaScript and TypeScript. ESLint 9.x introduces **flat config** (eslint.config.js), replacing legacy .eslintrc files with a more flexible, composable system.

## Core Expertise

**What is ESLint?**
- **Linter**: Finds and fixes problems in JavaScript/TypeScript code
- **Pluggable**: Extensive ecosystem of plugins and rules
- **Configurable**: Highly customizable for project-specific needs
- **Flat Config**: Modern configuration system (ESLint 9.x+)

**Key Capabilities**
- Detect bugs, anti-patterns, and code smells
- Enforce code style and best practices
- Fix issues automatically with `--fix`
- TypeScript support via typescript-eslint
- Framework-specific rules (React, Vue, Next.js)
- Import/export validation and sorting

## Installation

```bash
# Core ESLint
bun add --dev eslint

# TypeScript support
bun add --dev @typescript-eslint/parser @typescript-eslint/eslint-plugin

# Popular plugins
bun add --dev eslint-plugin-import eslint-plugin-react eslint-plugin-react-hooks

# Verify installation
bunx eslint --version
```

## Flat Config (ESLint 9.x)

### Basic Setup (eslint.config.js)

```javascript
// eslint.config.js
import js from '@eslint/js';

export default [
  js.configs.recommended,
  {
    rules: {
      'no-console': 'warn',
      'no-unused-vars': 'error',
    },
  },
];
```

### TypeScript Setup

```javascript
// eslint.config.js
import js from '@eslint/js';
import tseslint from '@typescript-eslint/eslint-plugin';
import tsparser from '@typescript-eslint/parser';

export default [
  js.configs.recommended,
  {
    files: ['**/*.ts', '**/*.tsx'],
    languageOptions: {
      parser: tsparser,
      parserOptions: {
        project: './tsconfig.json',
        ecmaVersion: 'latest',
        sourceType: 'module',
      },
    },
    plugins: {
      '@typescript-eslint': tseslint,
    },
    rules: {
      ...tseslint.configs.recommended.rules,
      '@typescript-eslint/no-unused-vars': 'error',
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/explicit-function-return-type': 'off',
    },
  },
];
```

### Recommended Production Setup

```javascript
// eslint.config.js
import js from '@eslint/js';
import tseslint from '@typescript-eslint/eslint-plugin';
import tsparser from '@typescript-eslint/parser';
import importPlugin from 'eslint-plugin-import';
import reactPlugin from 'eslint-plugin-react';
import reactHooksPlugin from 'eslint-plugin-react-hooks';

export default [
  // Base JavaScript rules
  js.configs.recommended,

  // Global ignores
  {
    ignores: [
      'dist/**',
      'build/**',
      'node_modules/**',
      '.next/**',
      'coverage/**',
      '*.config.js',
    ],
  },

  // TypeScript files
  {
    files: ['**/*.ts', '**/*.tsx'],
    languageOptions: {
      parser: tsparser,
      parserOptions: {
        project: './tsconfig.json',
        ecmaVersion: 'latest',
        sourceType: 'module',
        ecmaFeatures: {
          jsx: true,
        },
      },
    },
    plugins: {
      '@typescript-eslint': tseslint,
      import: importPlugin,
      react: reactPlugin,
      'react-hooks': reactHooksPlugin,
    },
    rules: {
      // TypeScript rules
      ...tseslint.configs.recommended.rules,
      '@typescript-eslint/no-unused-vars': [
        'error',
        { argsIgnorePattern: '^_', varsIgnorePattern: '^_' },
      ],
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/explicit-function-return-type': 'off',
      '@typescript-eslint/no-non-null-assertion': 'warn',
      '@typescript-eslint/consistent-type-imports': [
        'error',
        { prefer: 'type-imports' },
      ],

      // Import rules
      'import/order': [
        'error',
        {
          groups: [
            'builtin',
            'external',
            'internal',
            'parent',
            'sibling',
            'index',
          ],
          'newlines-between': 'always',
          alphabetize: { order: 'asc', caseInsensitive: true },
        },
      ],
      'import/no-duplicates': 'error',

      // React rules
      'react/react-in-jsx-scope': 'off', // Not needed in React 17+
      'react/prop-types': 'off', // Using TypeScript
      'react-hooks/rules-of-hooks': 'error',
      'react-hooks/exhaustive-deps': 'warn',
    },
    settings: {
      react: {
        version: 'detect',
      },
    },
  },

  // Test files - relaxed rules
  {
    files: ['**/*.test.ts', '**/*.test.tsx', '**/*.spec.ts', '**/*.spec.tsx'],
    rules: {
      '@typescript-eslint/no-explicit-any': 'off',
      'no-console': 'off',
    },
  },

  // JavaScript files
  {
    files: ['**/*.js', '**/*.cjs', '**/*.mjs'],
    rules: {
      'no-console': 'warn',
      'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    },
  },
];
```

## Essential Commands

```bash
# Lint all files
bunx eslint .

# Lint specific files
bunx eslint src/**/*.ts

# Auto-fix issues
bunx eslint --fix .

# Output JSON (for CI)
bunx eslint --format json --output-file eslint-report.json .

# Lint only changed files (with git)
bunx eslint $(git diff --name-only --diff-filter=ACMRTUXB main | grep -E '\.(js|ts|tsx)$')

# Debug configuration
bunx eslint --debug src/index.ts

# Print config for file
bunx eslint --print-config src/index.ts

# Cache results for faster subsequent runs
bunx eslint --cache --cache-location .eslintcache .
```

## Migration from Legacy .eslintrc

### Legacy Config (.eslintrc.json)

```json
{
  "extends": ["eslint:recommended", "plugin:@typescript-eslint/recommended"],
  "parser": "@typescript-eslint/parser",
  "parserOptions": {
    "project": "./tsconfig.json"
  },
  "plugins": ["@typescript-eslint"],
  "rules": {
    "no-console": "warn"
  }
}
```

### Flat Config Equivalent (eslint.config.js)

```javascript
import js from '@eslint/js';
import tseslint from '@typescript-eslint/eslint-plugin';
import tsparser from '@typescript-eslint/parser';

export default [
  js.configs.recommended,
  {
    files: ['**/*.ts', '**/*.tsx'],
    languageOptions: {
      parser: tsparser,
      parserOptions: {
        project: './tsconfig.json',
      },
    },
    plugins: {
      '@typescript-eslint': tseslint,
    },
    rules: {
      ...tseslint.configs.recommended.rules,
      'no-console': 'warn',
    },
  },
];
```

### Migration Steps

```bash
# 1. Update ESLint to 9.x
bun add --dev eslint@latest

# 2. Create eslint.config.js
touch eslint.config.js

# 3. Convert config (manual or with tools)
# Copy rules from .eslintrc to flat config

# 4. Test new config
bunx eslint .

# 5. Remove legacy files
rm .eslintrc.json .eslintrc.js .eslintignore

# 6. Update scripts in package.json
{
  "scripts": {
    "lint": "eslint .",
    "lint:fix": "eslint --fix ."
  }
}
```

## Popular Plugins

### TypeScript ESLint

```bash
bun add --dev @typescript-eslint/parser @typescript-eslint/eslint-plugin
```

```javascript
// eslint.config.js
import tseslint from '@typescript-eslint/eslint-plugin';
import tsparser from '@typescript-eslint/parser';

export default [
  {
    files: ['**/*.ts', '**/*.tsx'],
    languageOptions: {
      parser: tsparser,
      parserOptions: {
        project: './tsconfig.json',
      },
    },
    plugins: {
      '@typescript-eslint': tseslint,
    },
    rules: {
      ...tseslint.configs.recommended.rules,
      '@typescript-eslint/no-unused-vars': 'error',
      '@typescript-eslint/no-explicit-any': 'warn',
    },
  },
];
```

### Import Plugin

```bash
bun add --dev eslint-plugin-import
```

```javascript
import importPlugin from 'eslint-plugin-import';

export default [
  {
    plugins: {
      import: importPlugin,
    },
    rules: {
      'import/order': ['error', { 'newlines-between': 'always' }],
      'import/no-duplicates': 'error',
      'import/no-unresolved': 'error',
    },
  },
];
```

### React Plugins

```bash
bun add --dev eslint-plugin-react eslint-plugin-react-hooks
```

```javascript
import reactPlugin from 'eslint-plugin-react';
import reactHooksPlugin from 'eslint-plugin-react-hooks';

export default [
  {
    files: ['**/*.jsx', '**/*.tsx'],
    plugins: {
      react: reactPlugin,
      'react-hooks': reactHooksPlugin,
    },
    rules: {
      'react/react-in-jsx-scope': 'off',
      'react-hooks/rules-of-hooks': 'error',
      'react-hooks/exhaustive-deps': 'warn',
    },
    settings: {
      react: {
        version: 'detect',
      },
    },
  },
];
```

### Next.js Plugin

```bash
bun add --dev @next/eslint-plugin-next
```

```javascript
import nextPlugin from '@next/eslint-plugin-next';

export default [
  {
    plugins: {
      '@next/next': nextPlugin,
    },
    rules: {
      ...nextPlugin.configs.recommended.rules,
      '@next/next/no-html-link-for-pages': 'error',
    },
  },
];
```

## Ignoring Files

### Via eslint.config.js (Recommended)

```javascript
export default [
  {
    ignores: [
      'dist/**',
      'build/**',
      'node_modules/**',
      '*.config.js',
      'coverage/**',
    ],
  },
  // ... rest of config
];
```

### Via .eslintignore (Legacy, still supported)

```
dist/
build/
node_modules/
*.config.js
coverage/
```

## Editor Integration

### VS Code

**Install extension:**
```bash
code --install-extension dbaeumer.vscode-eslint
```

**Settings (.vscode/settings.json):**
```json
{
  "eslint.enable": true,
  "eslint.validate": [
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact"
  ],
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
  },
  "eslint.useFlatConfig": true
}
```

### Neovim

```lua
-- Using nvim-lspconfig
require('lspconfig').eslint.setup({
  cmd = { 'vscode-eslint-language-server', '--stdio' },
  filetypes = {
    'javascript',
    'typescript',
    'javascriptreact',
    'typescriptreact',
  },
  root_dir = require('lspconfig.util').root_pattern(
    'eslint.config.js',
    'eslint.config.mjs',
    'eslint.config.cjs',
    '.eslintrc.js'
  ),
  on_attach = function(client, bufnr)
    -- Auto-fix on save
    vim.api.nvim_create_autocmd('BufWritePre', {
      buffer = bufnr,
      command = 'EslintFixAll',
    })
  end,
})
```

## CI/CD Integration

### GitHub Actions

```yaml
name: ESLint
on:
  push:
    branches: [main]
  pull_request:

jobs:
  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: oven-sh/setup-bun@v2
        with:
          bun-version: latest

      - name: Install dependencies
        run: bun install --frozen-lockfile

      - name: Run ESLint
        run: bunx eslint . --max-warnings 0
```

### GitLab CI

```yaml
eslint:
  image: oven/bun:latest
  stage: test
  script:
    - bun install --frozen-lockfile
    - bunx eslint . --max-warnings 0
  only:
    - merge_requests
    - main
```

## When to Use ESLint vs Biome

### Use ESLint When:
- ✅ Need React Hooks linting (`eslint-plugin-react-hooks`)
- ✅ Framework-specific rules (Next.js, Nuxt, Angular)
- ✅ Import validation and sorting (`eslint-plugin-import`)
- ✅ Accessibility linting (`eslint-plugin-jsx-a11y`)
- ✅ Complex custom rules for business logic
- ✅ Legacy codebase with extensive ESLint config

### Use Biome When:
- ✅ Starting a new project
- ✅ Want zero-config setup
- ✅ Need fast CI/CD pipelines (15-20x faster)
- ✅ Standard JavaScript/TypeScript without special plugins
- ✅ Want all-in-one tooling (format + lint + organize imports)

### Hybrid Approach
Use **Biome for formatting**, **ESLint for specialized linting**:

```javascript
// eslint.config.js
export default [
  {
    rules: {
      // Disable stylistic rules (handled by Biome)
      'no-multiple-empty-lines': 'off',
      'comma-dangle': 'off',
      'quotes': 'off',

      // Keep logic/bug detection rules
      'no-unused-vars': 'error',
      'no-console': 'warn',
      'react-hooks/rules-of-hooks': 'error',
    },
  },
];
```

## Troubleshooting

### Flat Config Not Detected

```bash
# Check if ESLint sees the config
bunx eslint --debug .

# Verify config file name
ls eslint.config.{js,mjs,cjs}

# Ensure ESLint 9.x is installed
bunx eslint --version
```

### TypeScript Parsing Errors

```bash
# Verify tsconfig.json path is correct
bunx eslint --print-config src/index.ts

# Check parser options
# In eslint.config.js:
parserOptions: {
  project: './tsconfig.json',  // Relative to eslint.config.js
  tsconfigRootDir: import.meta.dirname,  // ESM
}
```

### Slow Linting Performance

```bash
# Enable caching
bunx eslint --cache .

# Lint only changed files
bunx eslint $(git diff --name-only main | grep -E '\.(js|ts|tsx)$')

# Use --max-warnings to fail fast
bunx eslint --max-warnings 0 .

# Consider switching to Biome for faster linting
```

### Plugin Not Working

```javascript
// Ensure plugin is imported and added to plugins object
import importPlugin from 'eslint-plugin-import';

export default [
  {
    plugins: {
      import: importPlugin,  // Must match rule prefix
    },
    rules: {
      'import/order': 'error',  // Prefix matches plugin name
    },
  },
];
```

## References

- Official docs: https://eslint.org
- Flat config: https://eslint.org/docs/latest/use/configure/configuration-files
- Migration guide: https://eslint.org/docs/latest/use/configure/migration-guide
- typescript-eslint: https://typescript-eslint.io
- Rules reference: https://eslint.org/docs/rules/
