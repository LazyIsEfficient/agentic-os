# CLAUDE.md Template

```markdown
# Project: [Name]

## Tech Stack
- React 18, TypeScript 5, Vite, Tailwind CSS 4
- Node.js 22, Express, PostgreSQL, Prisma

## Commands
- Build: `npm run build`
- Test: `npm test`
- Lint: `npm run lint --fix`
- Dev: `npm run dev`
- Type check: `npx tsc --noEmit`

## Code Conventions
- Functional components with hooks (no class components)
- Named exports (no default exports)
- colocate tests next to source: `Button.tsx` → `Button.test.tsx`
- Use `cn()` utility for conditional classNames
- Error boundaries at route level

## Boundaries
- Never commit .env files or secrets
- Never add dependencies without checking bundle size impact
- Ask before modifying database schema
- Always run tests before committing

## Patterns
[One short example of a well-written component in your style]
```
