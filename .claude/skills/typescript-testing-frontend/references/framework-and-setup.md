# Test Framework and Setup

## Test Framework

- **Jest 29.7.0**: Primary test runner
- **@swc/jest**: TypeScript/JSX transpiler (fast SWC-based compilation, not Babel)
- **React Testing Library 16.x**: Component and hook testing (`@testing-library/react`)
- **@testing-library/jest-dom 6.x**: Extended DOM assertions (`toBeInTheDocument()`, etc.)
- **jest-canvas-mock**: Canvas element polyfill
- **Test environment**: `jsdom`
- **Test timeout**: 90 seconds
- **Config**: `apps/platform-app/config/jest/jest.config.js`
- **Test scripts**:
  ```json
  "test": "jest --config ./config/jest/jest.config.js --setupFiles ./config/jest/env.setup.js"
  "test:ci": "jest --config ./config/jest/jest.config.js --setupFiles ./config/jest/env.setup.js --maxWorkers=2 --ci"
  ```

## Setup Files

- `config/jest/jest.setup.js` — imports `@testing-library/jest-dom` and `jest-canvas-mock`, polyfills `TextEncoder`, `TextDecoder`, `structuredClone`, `ResizeObserver`, `Request`, `Response`, `Headers`
- `config/jest/env.setup.js` — loads environment variables from `.env`

## Key Dependencies

| Library | Version | Purpose |
|---|---|---|
| `@chakra-ui/react` | ^3.33.0 | UI framework |
| `@tanstack/react-query` | ^5.66.9 | Data fetching / server state |
| `zustand` | ^5.0.3 | Client state management |
| `next` | 15.x | Framework (App Router) |
| `thirdweb` | — | Web3 wallet connection |
