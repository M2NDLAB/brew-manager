# Security Policy

## Supported Versions

brew-manager follows a single-branch release model. Only the latest version on `main` receives security updates and bug fixes.

| Version | Supported |
|---------|-----------|
| latest (main) | ✅ |
| older releases | ❌ |

If you are running an older version, update to the latest release before reporting an issue.

---

## What this tool does — security context

brew-manager is a shell script that runs with your user account privileges. It does not require `sudo` or root access for any of its standard operations. It reads and writes only within its own directory (`logs/`, `backups/`, `agents/`) and interacts with Homebrew, macOS LaunchAgents, and optionally the Mac App Store via `mas`.

The only network activity performed by this script is:
- `brew update` / `brew upgrade` — standard Homebrew operations
- `mas upgrade` — if you use the MAS module and confirm the upgrade
- Homebrew installation — if brew is not present and you confirm the install

No data is sent to M2NDLAB or any third party.

---

## Reporting a Vulnerability

If you discover a security vulnerability in brew-manager — for example a case where the script could be used to execute unintended commands, escalate privileges, or expose sensitive data — please report it responsibly.

**Do not open a public GitHub issue for security vulnerabilities.**

Instead, report privately via one of these methods:

- **GitHub Security Advisories** — open a private advisory at:
  `https://github.com/M2NDLAB/brew-manager/security/advisories/new`
- **Email** — if you prefer, contact the maintainer directly through the GitHub profile:
  `https://github.com/M2NDLAB`

### What to include in your report

- A clear description of the vulnerability
- Steps to reproduce it
- The version or commit hash you tested on
- What impact you believe it could have

### What to expect

- Acknowledgement within **72 hours**
- An assessment of severity and scope within **7 days**
- A fix or mitigation published as soon as reasonably possible, with credit to the reporter if desired

If the vulnerability is confirmed, a patched release will be pushed to `main` and a security advisory will be published on GitHub. If the report is not accepted (e.g. the behavior is intentional or out of scope), you will receive a clear explanation.

---

## Scope

Issues in scope for security reports:
- Command injection or unintended code execution
- Privilege escalation
- Unintended file reads, writes, or deletions outside the script's directory
- LaunchAgent abuse (e.g. agents that persist after removal)

Out of scope:
- Vulnerabilities in Homebrew, `mas`, or macOS itself
- Issues that require the attacker to already have full access to your user account
- Social engineering

---

*Thank you for helping keep brew-manager and its users safe.*
