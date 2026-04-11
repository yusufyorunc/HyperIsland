# Security Policy

## Scope and Context

HyperIsland is an Android application/module that integrates with LSPosed and System UI behavior on rooted devices.
Because this project can interact with notification flows and privileged runtime environments, responsible vulnerability handling is important.

This policy applies to:

- Source code in this repository
- Official release artifacts published from this repository
- Security-impacting behavior introduced by HyperIsland integrations

This policy does not cover vulnerabilities that exist only in third-party platforms (for example, Android OS, LSPosed, HyperOS, or device firmware) unless HyperIsland directly introduces or worsens the issue.

## Supported Versions

Security fixes are provided for actively maintained code only.

| Version                                               | Supported          |
| ----------------------------------------------------- | ------------------ |
| `master` (default branch)                             | :white_check_mark: |
| Latest release line (`v1.9.x` at the time of writing) | :white_check_mark: |
| `v1.8.x` and older                                    | :x:                |

If you report a vulnerability in an unsupported version, you may be asked to reproduce it on the latest supported release.

## Reporting a Vulnerability

### Preferred private channel

Use GitHub Private Vulnerability Reporting (Security Advisories):

- https://github.com/yusufyorunc/HyperIsland/security/advisories/new

### Alternative private channel (Email)

If you cannot use GitHub Security Advisories, report by email:

- yusufyorunc@mail.com

Recommended subject format: `[SECURITY] <short title>`

Please do not open a public issue for unpatched vulnerabilities.

### If private reporting is unavailable

Open a GitHub issue titled `SECURITY: Private Contact Request` with no technical details, and ask for a private channel.

## What to Include in a Report

To help triage quickly, include:

- Affected version (for example, `1.9.9+2047`) and installation source
- Device model, Android/HyperOS version, and LSPosed version
- Clear reproduction steps and required preconditions
- Proof of concept or minimal test case
- Security impact assessment (confidentiality, integrity, availability)
- Relevant logs/screenshots with secrets and personal data removed

## Severity Classification (CVSS v3.1)

HyperIsland uses CVSS v3.1 base scores for severity classification.
The initial score may be adjusted during triage based on real-world exploitability and deployment context.

| Severity      | CVSS v3.1 Base Score |
| ------------- | -------------------- |
| Critical      | 9.0-10.0             |
| High          | 7.0-8.9              |
| Medium        | 4.0-6.9              |
| Low           | 0.1-3.9              |
| Informational | 0.0                  |

## Triage and Response Targets

The maintainer aims for the following response times:

- Initial acknowledgment: within 3 business days
- Triage decision: within 7 business days
- Progress updates: at least every 14 days for confirmed issues

Target remediation windows (best effort):

| Severity      | CVSS v3.1 Base Score | Target                              |
| ------------- | -------------------- | ----------------------------------- |
| Critical      | 9.0-10.0             | 7-14 days                           |
| High          | 7.0-8.9              | 30 days                             |
| Medium        | 4.0-6.9              | Next planned release cycle          |
| Low           | 0.1-3.9              | Best effort / backlog               |
| Informational | 0.0                  | Documentation/update note as needed |

Actual timelines can vary depending on complexity, upstream dependencies, and maintainer availability.

## Coordinated Disclosure

- Do not publicly disclose vulnerability details before a fix or mitigation is available.
- After a fix is released, coordinated public disclosure is welcome.
- Security fixes may be released before full technical details to protect users.

## Researcher Guidelines

Security research performed in good faith is welcome. Please:

- Avoid privacy violations, service disruption, and destructive testing
- Use the minimum data needed to demonstrate impact
- Do not access accounts or data that you do not own or have permission to test

Reports that include clear reproduction and impact details are prioritized.
