---
name: security-hardening
description: Apply security-first practices when building or reviewing code — input validation, secrets management, auth checks, OWASP Top 10 coverage. Triggered by "security review", "harden this", "is this secure", "security-hardening", "check for vulnerabilities", "audit my code", "run a security check", "is there anything unsafe here", "check for SQL injection", "check for XSS", "are there any security issues".
attribution: >
  Independently written. OWASP Top 10 and secure coding practices are
  publicly documented standards. The boundary-system structure and pre-deployment
  checklist in this skill were informed by patterns in agent-skills
  (github.com/addyosmani/agent-skills, © Addy Osmani, MIT License).
  No text was copied; this file is an original work.
---

# 🛡️ Skill: security-hardening

## Purpose

Security retrofitted after the fact costs 10× more than security built in. This skill applies a consistent security lens at write-time and review-time — not as an afterthought audit. It covers the OWASP Top 10 patterns that appear most frequently in real deliverables.

## Trigger phrases

- "security review"
- "harden this"
- "is this secure"
- "security-hardening"
- "check for vulnerabilities"
- "review this for security issues"

---

## Boundary system (apply at all times)

### Always do — no exceptions

| Rule | Example |
|------|---------|
| Validate all external input at the system boundary | `zod.parse(req.body)` before any business logic |
| Parameterize all DB queries — never concatenate user input into SQL | `db.query('SELECT * FROM users WHERE id = $1', [id])` |
| Hash passwords with a slow algorithm | bcrypt, argon2 — never MD5, SHA-1, or plain SHA-256 |
| Use environment variables for all secrets | `process.env.API_KEY` — never hardcoded strings |
| Set security headers | `Content-Security-Policy`, `X-Frame-Options`, `X-Content-Type-Options` |
| Enforce HTTPS | Redirect HTTP → HTTPS; set `Secure` flag on cookies |

### Ask first — requires human approval

- Any change to authentication or session management
- New endpoints that accept file uploads
- New third-party integrations that receive user data
- Any change to user roles or permission logic
- Storing a new category of sensitive data (PII, payment, health)

### Never do

- Commit secrets, tokens, or credentials to version control — even in test files
- Log passwords, tokens, or PII to stdout/files
- Trust client-side validation as a security boundary
- Expose raw stack traces or internal error details to end users
- Use `eval()`, `exec()`, or equivalents on user input
- Disable security linting rules to make CI pass

---

## Steps

### 1. Identify the attack surface

Before reviewing or writing code, map:
- What inputs does this code accept? (HTTP request, file upload, env var, DB read, IPC)
- What does it output? (HTTP response, DB write, file write, shell command)
- What trust boundaries does it cross?

### 2. Check OWASP Top 10 coverage

Work through the relevant categories for the code in scope:

| # | Category | What to check |
|---|----------|--------------|
| A01 | Broken Access Control | Every endpoint checks auth AND authorisation (not just "is logged in") |
| A02 | Cryptographic Failures | No sensitive data transmitted unencrypted; no weak algorithms |
| A03 | Injection | All SQL/shell/LDAP inputs parameterised; no string concatenation with user input |
| A04 | Insecure Design | Business logic can't be bypassed by manipulating request params |
| A05 | Security Misconfiguration | No default credentials; debug mode off in production; minimal permissions |
| A06 | Vulnerable Components | `npm audit` / `pip-audit` run; high/critical findings resolved |
| A07 | Auth Failures | Sessions expire; tokens invalidated on logout; no weak password rules |
| A08 | Software/Data Integrity | Dependencies pinned; no unverified third-party scripts |
| A09 | Logging Failures | Security events logged (login, auth failure, permission denied) — without logging the secret itself |
| A10 | SSRF | Outbound HTTP calls validated against an allowlist; no user-controlled URLs fetched server-side without validation |

### 3. Flag findings with severity

For each issue found:

```
[HIGH]   SQL injection risk — user input concatenated into query at api/users.ts:42
[MEDIUM] Missing authorisation check — any authenticated user can access /admin/export
[LOW]    Security header X-Frame-Options not set in middleware
[INFO]   bcrypt work factor is 10 — consider 12 for new deployments
```

Severity guide:
- **HIGH** — exploitable by an unauthenticated user or directly exposes data
- **MEDIUM** — exploitable by an authenticated user or requires specific conditions
- **LOW** — defence-in-depth gap, not directly exploitable
- **INFO** — best-practice recommendation, no immediate risk

### 4. Pre-deployment security checklist

Run this before any production deployment:

```
Authentication & Sessions
  [ ] Passwords hashed with bcrypt/argon2 (work factor ≥ 12)
  [ ] Session tokens expire and are invalidated on logout
  [ ] MFA available for admin accounts

Authorisation
  [ ] Every endpoint checks both authentication AND authorisation
  [ ] No IDOR — IDs in requests are validated as belonging to the requesting user

Input Validation
  [ ] All external input validated at the boundary (schema validation)
  [ ] File uploads: type checked, size limited, stored outside web root

Data Protection
  [ ] No secrets in code, config files, or logs
  [ ] PII encrypted at rest if stored
  [ ] HTTPS enforced; HSTS header set

Dependencies
  [ ] npm audit / pip-audit run with zero high/critical findings
  [ ] No packages with known critical CVEs

Infrastructure
  [ ] Debug mode / verbose errors disabled in production
  [ ] Minimal IAM permissions (least privilege)
  [ ] No default credentials on any service
```

### 5. Report

```
Security review: <filename or scope>

Findings:
  [HIGH]   <description> — <file>:<line>
  [MEDIUM] <description> — <file>:<line>
  [LOW]    <description> — <file>:<line>

Pre-deployment checklist: ✓ / ✗ (list failed items)

Recommendation: <fix HIGH findings before merging / safe to merge with noted caveats>
```

---

## Guardrails

- Never mark a HIGH finding as acceptable without explicit user confirmation.
- Never add a dependency to fix a security issue without verifying the dependency itself is not a bigger risk.
- If a security fix requires a design change (e.g. the entire auth model is wrong), surface it as a separate task — do not silently work around it.
- Do not remove or disable security linting rules to make CI pass.

## Gotchas
- If `npm audit` / `pip-audit` isn't installed or can't run (offline, no lockfile), report that check as **SKIP** with the reason — never silently drop it from the report as if it passed.
- Applying the OWASP checklist to test fixtures, seed data, or sample/demo code as if it were production surfaces false HIGH findings (hardcoded test credentials are often intentional) — confirm the scope is actually production-reachable code before flagging.
- A parameterized query still isn't safe if the table or column name itself is built from user input — parameter binding only protects values, not identifiers; check for string-built identifiers separately under A03.
