# audit-github-repo — Deep reference

Loaded by Claude only on Deep audits or when the Quick pass surfaces something needing depth. The top-level `SKILL.md` is the methodology; this file is the catalog.

## Table of contents

1. [Historical supply-chain attacks](#historical-supply-chain-attacks)
2. [Full secret-regex library](#full-secret-regex-library)
3. [Obfuscation indicators](#obfuscation-indicators)
4. [Persistence mechanisms by OS](#persistence-mechanisms-by-os)
5. [Per-language deep grep patterns](#per-language-deep-grep-patterns)
6. [Channel-by-channel verification](#channel-by-channel-verification)
7. [Native code red flags](#native-code-red-flags)
8. [External scanner toolbox](#external-scanner-toolbox)
9. [Reproducibility & provenance](#reproducibility--provenance)
10. [Typosquat heuristics](#typosquat-heuristics)

---

## Historical supply-chain attacks

Pin or refuse versions matching any of these. This is a non-exhaustive list — when in doubt, check the GitHub Advisory Database (`gh api graphql` query in SKILL.md Phase 5).

### npm

| Package | Versions | Year | Payload |
|---|---|---|---|
| `event-stream` | ≥ 3.3.6 | 2018 | Embedded `flatmap-stream`, targeted `copay` Bitcoin wallets |
| `flatmap-stream` | any | 2018 | Credential exfil for `copay` |
| `eslint-scope` | 3.7.2 | 2018 | npm token stealer |
| `ua-parser-js` | 0.7.29, 0.8.0, 1.0.0 | 2021 | Coinminer + credential stealer (DanaBot) |
| `coa`, `rc` | various 2021 | 2021 | Same author as `ua-parser-js`, same payload |
| `colors.js` | 1.4.1+, `faker.js` 6.6.6 | 2022 | Author sabotage — infinite loop / "Liberty Liberty Liberty" |
| `node-ipc` | 10.1.1 / 10.1.2 / 11.0.0+ | 2022 | Protestware: geo-targeted file wipe (Russia/Belarus IPs) |
| `peacenotwar` | any | 2022 | Same author, payload-bearing dep |
| `web3.js` (Solana) | 1.95.6, 1.95.7 | 2024 | Stole private keys |
| `lottie-player` (LottieFiles) | 2.0.5, 2.0.6, 2.0.7 | 2024 | Crypto-drainer injection |
| `tj-actions/changed-files` (GitHub Action) | tampered tag | 2025 | Secret exfil via stdout-to-CI-logs |
| `rspack-cli`, `rspack-core` | 1.1.7 | 2024 | Crypto miner |

### PyPI

| Package | Year | Payload |
|---|---|---|
| `ctx` | 2022 | AWS credential exfil — replaced legit package |
| `phpass` (typo of `passlib`) | 2022 | Same author as `ctx` |
| `colorama` typosquats (`colorsama`, `colourama`, etc.) | 2022 | Multiple |
| `discord.dll`, `discordsafe`, etc. | ongoing | Discord token stealer family |
| `pytoileur`, `pyrologin` | 2024 | Cookie / wallet stealer |
| `requests-darwin-lite` | 2024 | macOS persistence + RAT |
| `pip-tools` (typo: `piptools`) | 2024 | Cred stealer |

### crates.io

| Package | Year | Payload |
|---|---|---|
| `serde_jsonl` (typosquat of `serde_json`) | 2022 | Refused publish, attempted typosquat |
| `bigint-ng`, `digi`, etc. small typosquats | ongoing | Refused or yanked |

Cargo has been comparatively clean — registry policy refuses postinstall hooks at install (only `build.rs` at compile, which still runs arbitrary code).

### RubyGems

| Package | Year | Payload |
|---|---|---|
| `rest-client` | 1.6.13 | 2019 | Credential exfil |
| `bootstrap-sass` | 3.2.0.3 | 2019 | Backdoor on Rails apps |
| Various typosquats of `atlas_client`, `aws-sdk`, etc. | 2019-ongoing | Cred steal / cryptominer |

### System / language toolchain

| Target | Year | Payload |
|---|---|---|
| `xz utils` | 5.6.0, 5.6.1, CVE-2024-3094 | 2024 | sshd backdoor in libsystemd link path; planted by long-game social-engineering account "Jia Tan" |
| `linux-kernel` (lkmpg fork) | various | Test malicious modules |
| `Ledger Connect Kit` | 2023 | Crypto-drainer in 1.1.0/1.1.1/1.1.2 |
| `tj-actions/changed-files` | 2025 | GitHub Action secret exfil |
| `reviewdog/action-setup` | 2025 | Tag tampering |

### Browser extensions

Periodic mass compromises through extension acquisitions. Heuristic: extensions sold to a new owner that suddenly add `<all_urls>` permissions or update post-acquisition with obfuscated code. Check `web-stats.dev` / `cwsdash.com` for ownership history when available.

---

## Full secret-regex library

Run these as a single Grep with `-i` and the `output_mode: "content"`. Every hit is presumed positive until manually triaged.

```
# AWS
AKIA[0-9A-Z]{16}                           # AWS access key ID
ASIA[0-9A-Z]{16}                           # AWS temporary key ID
aws_secret_access_key\s*=\s*["']?[A-Za-z0-9/+=]{40}

# GitHub
ghp_[A-Za-z0-9]{36}                        # personal access token
gho_[A-Za-z0-9]{36}                        # OAuth token
ghu_[A-Za-z0-9]{36}                        # user-to-server token
ghs_[A-Za-z0-9]{36}                        # server-to-server token
ghr_[A-Za-z0-9]{36}                        # refresh token
github_pat_[A-Za-z0-9_]{82}                # fine-grained PAT

# OpenAI / Anthropic / Google
sk-[A-Za-z0-9]{20,}                        # OpenAI API key (also matches Anthropic style)
sk-ant-[A-Za-z0-9-]{20,}                   # Anthropic
AIza[0-9A-Za-z_-]{35}                      # Google API key
ya29\.[0-9A-Za-z_-]+                       # Google OAuth access token

# Slack / Discord
xox[baprs]-[A-Za-z0-9-]{10,}               # Slack token
[A-Za-z\d]{24}\.[\w-]{6}\.[\w-]{27}        # Discord bot token

# Stripe
sk_live_[A-Za-z0-9]{24,}                   # Stripe live secret
pk_live_[A-Za-z0-9]{24,}                   # Stripe live publishable
rk_live_[A-Za-z0-9]{24,}                   # Stripe restricted

# JWT
eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}

# Private keys
-----BEGIN (RSA |EC |DSA |OPENSSH |PGP )?PRIVATE KEY-----

# npm / cargo / pypi
npm_[A-Za-z0-9]{36}                        # npm access token
pypi-AgEIcHlwaS5vcmc[A-Za-z0-9_-]+         # PyPI API token (base64 prefix decodes to "pypi.org")
crates_io_[A-Za-z0-9]{32}                  # cargo token

# Generic high-entropy
password\s*[:=]\s*["'][^"']{6,}["']        # password literal
secret\s*[:=]\s*["'][^"']{6,}["']
api_?key\s*[:=]\s*["'][^"']{16,}["']
client_secret\s*[:=]\s*["'][^"']{16,}["']

# Database
postgres(ql)?://[^\s"']+:[^\s"']+@         # full connection string with embedded creds
mysql://[^\s"']+:[^\s"']+@
mongodb(\+srv)?://[^\s"']+:[^\s"']+@
redis://[^@\s"']+:[^@\s"']+@
```

For Deep audits with `gitleaks` installed, run it instead — it catches more.

---

## Obfuscation indicators

When code looks like it's hiding something, grep for these:

```
# Long encoded blobs (decode then audit the result)
[A-Za-z0-9+/]{500,}={0,2}                  # base64
\\x[0-9a-f]{2}(?:\\x[0-9a-f]{2}){200,}     # \xNN escape sequences
%[0-9a-f]{2}(?:%[0-9a-f]{2}){200,}         # url-encoded blocks

# Char-code arrays (JS classic)
String\.fromCharCode\([\d, ]{200,}\)
\[[\d, ]{500,}\]\.map\(.*fromCharCode

# Eval-of-decoded
atob\([^)]+\).*eval
Buffer\.from\([^)]+,\s*['"]base64['"]\)\.toString\(\).*(?:eval|Function)
codecs\.decode\(.*\)\s*\)\s*\)?\s*$        # python codecs.decode chain

# Packed JS (P.A.C.K.E.R.)
eval\(function\(p,a,c,k,e

# JSFuck / heavy bracket-only code
[(\[!+]{200,}

# Hidden RTL trick (Trojan Source)
‮|‭|‫|‪                # bidi override chars in source

# Homoglyph variables (lookalike Unicode)
[а-я]                             # Cyrillic letters in identifiers (a vs а)
```

Trojan Source attacks (CVE-2021-42574) hide code with bidi-override Unicode. `git log -p --color=always | grep -P '[\x{202a}-\x{202e}]'` on a Deep audit.

---

## Persistence mechanisms by OS

If a tool is installed once, what could it leave behind that runs forever after?

### macOS

- `~/Library/LaunchAgents/*.plist` — runs at login
- `/Library/LaunchAgents`, `/Library/LaunchDaemons` — system-wide
- `~/Library/Preferences/com.apple.loginitems.plist`
- `crontab -l`
- `~/.zshrc`, `~/.zprofile`, `~/.bash_profile`, `~/.bashrc` — shell hooks
- Login items via `osascript`
- Kernel extensions in `/Library/Extensions` (signed required since macOS 10.15)
- DYLD_INSERT_LIBRARIES env var

### Linux

- `/etc/systemd/system/*.service`, `~/.config/systemd/user/*.service`
- `crontab -l`, `/etc/cron.{d,daily,hourly,monthly,weekly}/`
- `/etc/rc.local`, `/etc/init.d/`
- `~/.bashrc`, `~/.zshrc`, `~/.profile`
- `~/.config/autostart/*.desktop`
- udev rules in `/etc/udev/rules.d/`
- LD_PRELOAD env var, `/etc/ld.so.preload`
- PAM modules in `/etc/pam.d/`

### Windows

- `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`
- `HKLM\Software\Microsoft\Windows\CurrentVersion\Run`
- `HKLM\System\CurrentControlSet\Services\` (services)
- Scheduled Tasks (`schtasks`, Task Scheduler)
- Startup folder: `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup`
- WMI event subscriptions
- AppInit_DLLs registry value
- COM hijacks under `HKCR\CLSID\`
- PowerShell profile: `$PROFILE`

### Cross-platform (dev surface)

- VSCode `tasks.json` `runOptions.runOn: "folderOpen"`
- Git hooks: `.git/hooks/post-checkout`, `post-merge`, `post-commit`
- Direnv `.envrc` execution
- `.vscode/settings.json` `terminal.integrated.profiles.*.args`

If the audited tool writes to any of these on install, that's a Critical finding.

---

## Per-language deep grep patterns

These extend the SKILL.md table. Run when the language is the primary surface.

### JavaScript / TypeScript / Node

```
# Network — beyond the basics
require\(['"]http2?['"]\)
require\(['"]net['"]\)
require\(['"]dgram['"]\)                   # UDP
require\(['"]dns['"]\)
fetch\(`\$\{[^}]+\}                         # fetch with template-string URL (dynamic)
\.(get|post|put|delete)\(\s*[`'"][^`'"]*\$\{ # axios with template URL

# Worker / sandbox escape
new Worker\(.*data:                        # data: URL workers
new Worker\(.*blob:
require\(['"]vm['"]\).*runInNewContext

# Native add-on load
require\(['"]node-gyp-build['"]\)
\.node['"]                                 # native bindings

# Postinstall surface
"scripts"\s*:\s*\{[^}]*"(?:pre|post)?install"
"binary"\s*:\s*\{                          # node-pre-gyp downloads binary at install

# Electron-specific
nodeIntegration\s*:\s*true
contextIsolation\s*:\s*false
webSecurity\s*:\s*false
allowRunningInsecureContent\s*:\s*true
shell\.openExternal\(.*\$\{                # remote-controllable shell.open

# Browser-only egress
navigator\.sendBeacon
new EventSource
WebSocket\(['"]wss?:
postMessage\(.*['"]?\*['"]?               # postMessage with wildcard target
```

### Python

```
# Network
import socket
import ssl
http\.client
asyncio\.open_connection
ftplib\.|smtplib\.|telnetlib\.

# Deserialization
pickle\.loads?\(
pickle\.Unpickler\(
cPickle\.|dill\.loads
yaml\.load\([^)]*\)(?!\s*,\s*Loader=yaml\.SafeLoader)
shelve\.open
jsonpickle\.decode
pyyaml.*Loader\s*=\s*yaml\.Loader

# Dynamic import
__import__\(.*\$\{?
importlib\.import_module\(

# Setup-time code execution
^from\s+setuptools|^from\s+distutils.*import.*setup
# ... and inside setup.py: any subprocess/urllib at module top level

# Code-as-data
exec\(open\(['"][^'"]+['"]\)\.read\(\)\)
compile\(.*['"]exec['"]\)

# C-extension load
ctypes\.CDLL\(
ctypes\.windll\.|ctypes\.cdll\.
cffi\.FFI\(\)\.dlopen
```

### Go

```
# Network beyond http
net\.Listen\(
net\.ListenPacket\(
syscall\.Socket\(

# Plugin / dynamic
plugin\.Open\(
reflect\.MakeFunc\(
unsafe\.Pointer

# CGO surface
import "C"
//\s*#cgo

# GitHub Action / CI helpers that leak
os\.Setenv\(.*os\.Getenv\(                 # env propagation
```

### Rust

```
# Unsafe surface
unsafe\s*\{
unsafe\s+impl
unsafe\s+fn

# Dynamic loading
libloading::Library
dlopen2::

# build.rs surface (runs at compile, but arbitrary code)
^use\s+std::process              # in build.rs
^use\s+reqwest                   # in build.rs — fetching at build = supply-chain risk

# FFI
extern\s+"C"
```

### Java / Kotlin / Android

```
# Reflection / dynamic class loading
DexClassLoader
PathClassLoader
Class\.forName\(
Method\.invoke\(

# JNI
System\.loadLibrary\(
System\.load\(

# Android-specific
android\.permission\.(INTERNET|READ_CONTACTS|RECORD_AUDIO|CAMERA|ACCESS_FINE_LOCATION|READ_EXTERNAL_STORAGE|WRITE_EXTERNAL_STORAGE|SEND_SMS|RECEIVE_SMS|READ_SMS|CALL_PHONE)
android:exported="true"                   # exported components — IPC surface
WebView.*setJavaScriptEnabled\(true\)
addJavascriptInterface\(

# Gradle build-time
buildscript\s*\{[^}]*repositories          # custom maven repos
apply\s+from:\s*['"]https?:                # remote build script
```

### C / C++

```
# Memory safety red flags (broad — many false positives, but worth a pass)
strcpy\(|strcat\(|sprintf\(|gets\(
memcpy\(.*,\s*[^,]+,\s*strlen          # potential off-by-one

# Privilege escalation
setuid\(|seteuid\(|setresuid\(

# Direct syscall
syscall\(\s*\d+
asm\s*\(

# Self-modifying / W^X violation
mprotect\(.*PROT_EXEC.*PROT_WRITE
VirtualAlloc.*PAGE_EXECUTE_READWRITE
```

### Ruby

```
# Dynamic
send\(:[\w]+\)                             # method dispatch from input
public_send\(
define_method\(

# Deserialization
Marshal\.load
YAML\.load[^_]
Oj\.load.*mode:\s*:object
```

### PHP

```
# Classic RCE
preg_replace\(.*/e['"]                     # /e modifier (deprecated, removed in PHP 7)
include\s*\(\s*\$
require\s*\(\s*\$
unserialize\(\s*\$_                         # unserialize on user input
$$\w+                                      # variable variables
```

### .NET / C#

```
# Dynamic
Activator\.CreateInstance\(.*Type\.GetType\(
CSharpCodeProvider                         # runtime compile
Assembly\.Load(?:Bytes|File)\(
Marshal\.GetDelegateForFunctionPointer
DllImport\("[^"]+\.dll"

# Deserialization
BinaryFormatter\(\)\.Deserialize          # deprecated, RCE risk
NetDataContractSerializer
LosFormatter
SoapFormatter
TypeNameHandling\s*=\s*TypeNameHandling\.(All|Auto|Objects)  # Newtonsoft RCE
```

### Shell

```
# Remote-then-execute
curl[^\n]+\|\s*(bash|sh|zsh|python|node)
wget\s+[^|]+\|\s*(bash|sh|zsh|python|node)
\$\(curl[^)]+\)
\$\(wget[^)]+\)

# Secret-handling smell
echo\s+\$\{?\w*(PASSWORD|SECRET|KEY|TOKEN)
> /dev/null 2>&1                           # output suppression around suspicious commands
```

### Docker

```
# Dockerfile risks
FROM\s+scratch                             # ok, but means no audit baseline
FROM\s+\w+\s*$                             # missing tag = "latest" drift
ADD\s+https?://                            # silent fetch, no checksum
ADD\s+git@                                 # silent git fetch
RUN\s+(curl|wget)[^\n]+\|\s*sh
USER\s+root\s*$                            # ends as root
--privileged                               # in compose / runtime
```

### Terraform / IaC

```
# Code execution surfaces
resource\s+"null_resource"
provisioner\s+"local-exec"
provisioner\s+"remote-exec"
data\s+"external"\s+"\w+"                  # runs an external program for input
data\s+"http"\s+"\w+"                      # fetches at plan time
```

---

## Channel-by-channel verification

Where to confirm a publisher is real.

### Obsidian community plugins

- Plugin store URL: `https://obsidian.md/plugins?search=<id>`
- Manifest: `manifest.json` at repo root with `id`, `name`, `version`, `minAppVersion`, `description`, `author`
- Audit `main.js` (the bundle) — Obsidian plugins ship as a single bundle plus optional `styles.css`
- Vault data flow: any call out to `app.vault.read()` / `metadataCache` shows what the plugin reads; combine with egress grep
- Sideloading via BRAT → no review, no auto-update gating

### VSCode extensions

- Marketplace URL: `https://marketplace.visualstudio.com/items?itemName=<publisher>.<name>`
- Verified publisher = blue checkmark
- `package.json` `activationEvents` — `*` means runs on every workspace open (broad surface)
- `contributes.commands`, `contributes.configuration` — what the extension exposes
- Telemetry: many extensions ship `vscode-extension-telemetry`; check `package.json` deps

### JetBrains plugins

- Marketplace URL: `https://plugins.jetbrains.com/plugin/<id>`
- "Verified" badge on plugin page
- `META-INF/plugin.xml` — declares all extension points

### Chrome / Firefox extensions

- Chrome Web Store: `https://chromewebstore.google.com/detail/<id>`
- Firefox AMO: `https://addons.mozilla.org/firefox/addon/<slug>/`
- `manifest.json` `permissions`, `host_permissions`, `content_scripts`, `web_accessible_resources`, `externally_connectable`
- Manifest V3 sandboxes more than V2 — V2-only extensions in 2026 are red flags
- Extension ownership history — community sites track sales (extensions are bought and weaponized)

### Claude Code plugins / MCP servers

- `manifest.json` for plugin metadata
- `mcp.json` / `.mcp.json` for MCP server config — check `command`, `args`, hostnames
- Subagent files in `agents/` — read each for `allowed-tools` and prompts
- Skills in `skills/<name>/SKILL.md` — check frontmatter and `allowed-tools`
- Hooks in `settings.json` patches — anything that auto-runs on `Stop` / `PreToolUse` is high-surface
- MCP servers run as long-lived processes with the access of whoever launches Claude Code — treat them like installed daemons

### Helm charts / Terraform modules

- Helm: `helm template` to see what gets rendered
- Terraform: `terraform plan` (without `apply`) to see what would happen — but plans can also execute `data "external"` and fetchers
- Pin module versions; never `master` / `main` references

### Docker images

- Pin by digest, not tag: `image@sha256:...`
- Run `trivy image <image>` or `grype <image>` for CVE scan
- Inspect `docker inspect <image>` — check `Config.Cmd`, `Config.Entrypoint`, exposed ports, volumes
- Watch for ENV with embedded credentials (image-build leaks)

---

## Native code red flags

When the artifact includes compiled native code:

- **No source published** — refuse for any tool that needs trust.
- **`build.rs` / `setup.py` / `binding.gyp` fetches code over the network at build time** — supply-chain via build.
- **Pre-built binaries not signed** — refuse unless reproducible builds + SLSA attestation cover the gap.
- **Kernel modules, eBPF programs, bootloader code** — Deep audit mandatory; defer to `security-reviewer` on Opus.
- **Code requesting `CAP_SYS_PTRACE`, `CAP_NET_ADMIN`, `CAP_SYS_MODULE`, etc.** — capability escalation.
- **DLL search-order surface (Windows)** — DLLs loaded by name in user-writable directories enable hijacking.

---

## External scanner toolbox

When installed locally, prefer these over manual grep:

| Scanner | Use | Install |
|---|---|---|
| `gitleaks detect --source <path>` | Secrets | `brew/scoop install gitleaks` |
| `trufflehog filesystem <path> --no-update` | Secrets w/ entropy + verification | `brew install trufflehog` |
| `semgrep --config auto <path>` | Pattern-based code scan (1000+ rules) | `pip install semgrep` |
| `osv-scanner -r <path>` | Cross-ecosystem CVE scan via OSV | `brew install osv-scanner` |
| `snyk test` | Dependency CVE | requires Snyk account |
| `cargo audit` | Rust deps | `cargo install cargo-audit` |
| `pip-audit` | Python deps | `pip install pip-audit` |
| `npm audit` | npm deps | bundled with npm |
| `govulncheck ./...` | Go deps + reachability | `go install golang.org/x/vuln/cmd/govulncheck@latest` |
| `bundler-audit` | Ruby deps | `gem install bundler-audit` |
| `trivy fs <path>` / `trivy image <img>` | Cross-stack vuln + secret + IaC | `brew install trivy` |
| `grype <path>` | Vuln scan | `brew install grype` |
| `syft <path>` | SBOM generation (use to feed grype) | `brew install syft` |

If none of these are available on the host, fall back to:
- GitHub Advisory Database via `gh api graphql` (see SKILL.md Phase 5)
- OSV.dev REST API: `curl https://api.osv.dev/v1/query -d '{"package":{"name":"<n>","ecosystem":"<e>"}}'`
- The grep patterns above

---

## Reproducibility & provenance

A claim is only as strong as the verification path:

- **Sigstore** — `cosign verify-blob` for binaries, `cosign verify` for container images. Look for `.sig` and `.cert` companion files in releases.
- **SLSA provenance** — `gh attestation verify <artifact> --owner <owner>` validates GitHub-attested builds.
- **Reproducible builds** — `https://reproducible-builds.org/` lists projects; rebuild and bit-compare.
- **Maven Central GPG signatures** — `gpg --verify <artifact>.asc <artifact>`.
- **PyPI / npm signatures** — historically weak; PyPI added Sigstore-based attestations in 2024 (verify with `pip install --require-hashes` against a SLSA-attested wheel).
- **SHA256 in README + signed commit** — weak, but better than nothing.

If the project ships pre-built binaries with no provenance, the audit's confidence is bounded by the bundle, not the source. Note that limit explicitly.

---

## Typosquat heuristics

Auto-flag when:

1. Name within Levenshtein distance 1-2 of a top-1000 popular package
2. Repo / package created within last 90 days
3. Single maintainer with no prior activity
4. README copy-pasted from the legitimate package (whole paragraphs match)
5. Description references a popular package's functionality but the source is structurally different
6. Different casing / hyphen / underscore variants of legitimate names (`color-utils` vs `color_utils` vs `colorutils`)

Cross-check against the legitimate package:

```bash
# npm
npm view <suspect-name> repository.url
npm view <legit-name> repository.url
# Compare. Different repos = potential squat.

# PyPI
pip show <suspect-name>
# Compare Project-URL / Home-page against the legit.
```

If suspicious: refuse install, suggest the legitimate name, and flag to the user.

---

## When to update this reference

When the audit catches a *new* attack pattern (a CVE, a fresh supply-chain compromise, an obfuscation technique not yet listed), add it here in the relevant section. The methodology in `SKILL.md` should stay stable; the catalog grows.

When the catalog grows past ~1000 lines, split by topic (`reference-supply-chain.md`, `reference-languages.md`, `reference-secrets.md`) and have `SKILL.md` load only the relevant slice.
