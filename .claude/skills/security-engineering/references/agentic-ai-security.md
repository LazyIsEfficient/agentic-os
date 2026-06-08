# Agentic AI Security (OWASP 2026)

When building or reviewing AI agent systems (e.g. an agent-orchestration framework):

| Risk | Description | Mitigation |
|------|-------------|------------|
| ASI01 | Goal Hijack — prompt injection alters objectives | Input sanitization, goal boundaries, behavioral monitoring |
| ASI02 | Tool Misuse — tools used unintended ways | Least privilege, fine-grained permissions, validate I/O |
| ASI03 | Identity & Privilege Abuse — delegated trust exploits | Short-lived scoped tokens, identity verification |
| ASI04 | Supply Chain — compromised plugins/MCP servers | Verify signatures, sandbox, allowlist plugins |
| ASI05 | Code Execution — unsafe code gen/execution | Sandbox execution, static analysis, human approval |
| ASI06 | Memory Poisoning — corrupted RAG/context | Validate stored content, segment by trust level |
| ASI07 | Insecure Inter-Agent Comms — spoofing/intercept | Authenticate, encrypt, verify message integrity |
| ASI08 | Cascading Failures — errors propagate across systems | Circuit breakers, graceful degradation, isolation |
| ASI09 | Human-Agent Trust Exploitation — over-trust manipulation | Label AI content, user education, verification steps |
| ASI10 | Rogue Agents — compromised agents acting maliciously | Behavior monitoring, kill switches, anomaly detection |

## Agent Security Checklist

- [ ] All agent inputs sanitized and validated
- [ ] Tools operate with minimum required permissions
- [ ] Credentials are short-lived and scoped
- [ ] Third-party plugins verified and sandboxed
- [ ] Code execution happens in isolated environments
- [ ] Agent communications authenticated and encrypted
- [ ] Circuit breakers between agent components
- [ ] Human approval for sensitive operations
- [ ] Behavior monitoring for anomaly detection
- [ ] Kill switch available for agent systems
