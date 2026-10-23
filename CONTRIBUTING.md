# Contributing to SiincosCharge

Thank you for your interest in contributing! Contributions of all kinds are welcome: bug fixes, new Modbus profiles for chargers and power meters, documentation improvements, and ideas.

## Ways to contribute

- **Report a bug or suggest a feature:** Open an issue and describe what you expected, what happened, and how to reproduce it. For hardware problems, please include your charger / power meter model and edge device.
- **Add new devices:** Support for a new EV charger or power meter is one of the most valuable contributions. Please include the model name, the documentation or source you used, and confirm that you tested it on real hardware. In addition, please also extend the documentation by providing the necessary steps to setup and configure the device (e.g. ModbusRTU configuration, setting maximum hardware current, etc.) 
- **Improve the documentation:** Typos, unclear steps and missing explanations are all worth fixing.
- **Fix a bug or add a feature:** See below.

## Before you start

For anything larger than a small fix, please open an issue first to discuss the idea. That avoids duplicate work and makes sure the change fits the project's direction.

## Pull requests

1. Fork the repository and create a branch from `main`.
2. Make your change. Keep each pull request focused on one topic.
3. Make sure the project builds and the existing tests pass, and add tests where it makes sense.
4. Describe in the pull request what you changed and why, and reference the related issue.
5. Be open to feedback. Reviews are meant to improve the change, not to criticize it.

Pull requests are reviewed and merged by the maintainer. Direct pushes to `main` are not accepted.

## Please don't commit

Credentials, access tokens, real device IDs, or personal data. Remove them from logs, screenshots and exported dashboards before submitting.

## Licensing of contributions

By submitting a contribution, you agree that it is licensed under the project's [Apache License 2.0](LICENSE). You confirm that you have the right to submit it, meaning you wrote it yourself or have permission to contribute it.

The SiincosCharge apps and any hosted services are separate products and are not part of this repository.

## Security issues

Please don't report security vulnerabilities in public issues. Use GitHub's private vulnerability reporting (Security tab) or contact the maintainer directly.

## Code of conduct

Be respectful and constructive. Harassment and personal attacks are not tolerated.
