# LINUXSQUAD v10

**LINUXSQUAD v10 is a Bash-based authorized web application security assessment framework designed for penetration testing, reconnaissance, and defensive security validation in environments where you have explicit permission to test.

The project combines multiple reconnaissance and verification techniques into a single workflow to help security professionals identify common web application weaknesses and infrastructure misconfigurations.

Features

- Automatic proxy discovery and rotation
- Tor and ProxyChains support
- Smart retry and exponential backoff
- Random User-Agent and header rotation
- Basic WAF identification
- Origin IP discovery attempts
- HTTP header analysis
- Server and CMS fingerprinting
- Endpoint enumeration
- HTTP Request Smuggling detection checks
- SQL Injection detection routines
- Cross-Site Scripting (XSS) detection routines
- Local File Inclusion (LFI) checks
- Server-Side Request Forgery (SSRF) checks
- Server-Side Template Injection (SSTI) checks
- Command Injection detection
- GraphQL endpoint enumeration
- CORS configuration checks
- Automatic vulnerability reporting
- Colored terminal interface
- Session and CSRF token collection
- Multi-phase scanning workflow

Scan Workflow

1. Proxy Discovery
2. Origin IP Enumeration
3. Infrastructure Reconnaissance
4. WAF Detection
5. HTTP Smuggling Checks
6. Injection Testing
7. Advanced Security Checks
8. Report Generation

Requirements

- Bash
- curl
- dig
- python3
- openssl
- bc

Optional tools:

- Tor
- ProxyChains
- WhatWeb
- sqlmap

Usage

Run the script and choose either a quick assessment or a full security assessment from the interactive menu.

Important Notice

This project is intended only for authorized security testing, laboratory environments, CTFs, or systems for which you have explicit written permission.

The author does not encourage or authorize testing systems without permission. Users are solely responsible for complying with applicable laws, organizational policies, and ethical security practices.

License**

Use responsibly and only within legal and authorized environments.<img width="1088" height="673" alt="18896" src="https://github.com/user-attachments/assets/0aa8e623-e70c-4a4f-8804-5f73e1deb0ab" />
