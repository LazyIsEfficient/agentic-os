# Pre-Merge Review Checklist

> Fillable checklist that walks the enforcer through a pre-merge review. Adapt the depth to the size and risk of the change. A trivial bug fix doesn't need every section; a major feature does.

## Header

- **PR / change:** _____
- **Author:** _____
- **Reviewer (enforcer):** _____
- **Date:** YYYY-MM-DD
- **Change shape:** bug fix | small feature | medium feature | large feature | refactor | configuration | dependency update | hotfix
- **Risk level:** low | medium | high | critical

---

## 1. Strategic Alignment

- [ ] **Relevant strategy section identified** (cite section): _____
- [ ] **Relevant DADs identified**: _____
- [ ] **Relevant ADRs identified**: _____
- [ ] **Conformance to load-bearing DADs**: ✅ conforms / ⚠️ partial / ❌ deviates
- [ ] **Conformance to ADRs**: ✅ conforms / ⚠️ partial / ❌ deviates
- [ ] **Conformance to strategic non-goals**: ✅ within scope / ❌ touches a non-goal
- [ ] **If deviation**, exception ADR filed: yes / no / not applicable

**Notes:** _____

---

## 2. Security Baseline

Routes to [security-engineering](../../security-engineering/SKILL.md). Skip categories that don't apply to this change.

- [ ] **Input validation**: user input is validated at the API boundary (Zod or equivalent)
- [ ] **Auth & authorization**: protected endpoints check auth; authorization on every request
- [ ] **SQL injection**: parameterized queries; no string concatenation
- [ ] **Secrets management**: secrets in vault, not in code or env files
- [ ] **Data exposure**: API responses don't leak data the requesting user shouldn't see
- [ ] **Logging**: sensitive data redacted (auth headers, PII)
- [ ] **Error handling**: errors don't leak stack traces or internal paths
- [ ] **Dependencies**: any new dependencies vetted; no known CVEs
- [ ] **Encryption**: TLS in transit; encryption at rest where required
- [ ] **Rate limiting**: public endpoints rate-limited
- [ ] **CSRF / XSS**: mitigations in place for browser-facing endpoints
- [ ] **Smart contracts (if applicable)**: contract security patterns; reentrancy guards; signature verification
- [ ] **Compliance scope**: PCI / HIPAA / GDPR / etc. — if relevant, compliance review done

**Notes:** _____

---

## 3. Quality Baseline

Routes to [software-design](../../software-design/SKILL.md), the relevant testing skills, and [ux-design](../../ux-design/SKILL.md).

### Code design
- [ ] **Layering**: domain code doesn't reach into infrastructure or transport
- [ ] **Composition**: code uses node/class composition over deep inheritance
- [ ] **Cohesion**: each module has one reason to change
- [ ] **Naming**: class and method names match what they do
- [ ] **No god classes / god scenes** in the change
- [ ] **No tight coupling** via direct paths or shared state

### Tests
- [ ] **Tests are present** for the change
- [ ] **Tests cover the changed code** (meaningfully, not just for coverage numbers)
- [ ] **Tests assert observable behavior**, not internal calls
- [ ] **Tests are deterministic and independent**
- [ ] **CI passes**
- [ ] **Test failures (if any) are addressed**

### Accessibility (UI changes)
- [ ] **WCAG AA contrast** for text and UI
- [ ] **Color is not the only signal**
- [ ] **Semantic HTML** used (button, link, heading, etc.)
- [ ] **Keyboard navigation** works
- [ ] **Focus indicators** visible
- [ ] **Form labels** present and associated
- [ ] **Alt text** for meaningful images
- [ ] **ARIA attributes** where needed
- [ ] **Animations** respect `prefers-reduced-motion`

### Microcopy (UI changes)
- [ ] **No lorem ipsum**; all text is final
- [ ] **Error messages** are specific and actionable
- [ ] **Empty states** explain what's there and what to do
- [ ] **Button labels** are verb + object
- [ ] **Translation keys** for user-facing strings (not literal strings)
- [ ] **Voice and tone** consistent with the rest of the product

### Documentation
- [ ] **User-facing docs** updated if user-visible behavior changed
- [ ] **API docs** updated if API changed
- [ ] **Code comments** for non-obvious decisions
- [ ] **CHANGELOG** entry (if maintained)

### API / contracts
- [ ] **Backwards compatible** (or migration path documented)
- [ ] **Deprecation period** for removed fields
- [ ] **Version bumped** appropriately
- [ ] **Consumers notified** if breaking

**Notes:** _____

---

## 4. Performance (when relevant)

- [ ] **No new allocations** in hot paths (without measurement)
- [ ] **No new database queries** in tight loops
- [ ] **No blocking calls** in `_Process` / hot paths
- [ ] **CI hasn't gotten noticeably slower**
- [ ] **Performance impact measured** if change is performance-relevant
- [ ] **Profile data attached** for hot-path changes

**Notes:** _____

---

## 5. Edge Cases

- [ ] **Empty / zero / null inputs** handled
- [ ] **Maximum / very large inputs** handled
- [ ] **Network failures** handled (where relevant)
- [ ] **Permission denied / unauthorized** paths handled
- [ ] **Concurrent / race conditions** considered
- [ ] **Backwards compatibility** with existing data

**Notes:** _____

---

## 6. Automated Checks

- [ ] **Linter** has run and passed
- [ ] **Formatter** has been applied
- [ ] **Type checker** has run and passed
- [ ] **Unit tests** have run and passed
- [ ] **Integration tests** have run and passed (where applicable)
- [ ] **Security scan** has run and passed
- [ ] **Accessibility scan** has run and passed (UI changes)
- [ ] **Bundle size check** has run and passed (frontend, where applicable)

---

## 7. Verdict

- [ ] **Approved** — proceed to merge
- [ ] **Approved with conditions** — merge after fixing: _____
- [ ] **Needs revision** — address and re-review
- [ ] **Needs exception ADR** — file exception, then proceed
- [ ] **Blocked** — significant problem; discuss

### Top 3 things to fix (if needs revision)

1. _____
2. _____
3. _____

---

## 8. Sign-off

- [ ] Enforcer: _____ (date)
- [ ] PR author has seen and addressed feedback: _____
- [ ] Other reviewers have signed off (if applicable): _____

---

## Notes for the author

> Anything specific the enforcer wants the author to know.

> _____

---

> **Reminder**: this checklist is *adaptive*. Skip sections that don't apply. Use the right depth for the change. Trivial fixes get a light review; major features get a thorough one.
