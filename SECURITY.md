# Security Policy

## Supported versions

Security fixes are provided for the latest release on the `main` branch.

## Reporting a vulnerability

Use GitHub's private vulnerability reporting feature for this repository. Do not open a public issue for suspected credential exposure or a vulnerability with an active exploit path.

## Repository safety rules

This project must not track credentials, private keys, personal contact data, internal endpoints, machine-specific absolute paths, or local override files. Examples use reserved domains and placeholder values. Full Git history is scanned before publication and in CI.

If a real credential is committed, rotate it immediately. Deleting it in a later commit does not remove it from Git history.

