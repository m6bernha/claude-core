---
name: audit-github-repo
description: |
  Pre-install / pre-use safety audit for ANY third-party GitHub repository,
  in ANY language — Obsidian plugins, VSCode/JetBrains extensions, Claude
  Code plugins and MCP servers, browser extensions, npm/PyPI/cargo/go/maven/
  gem/composer/NuGet/CocoaPods packages, Docker images, Helm charts,
  Terraform modules, mobile-app SDKs, CLI binaries, Electron apps, kernel
  modules, and standalone scripts. Answers three questions: (1) where does
  data go and what API calls are made? (2) what security flaws and
  malicious patterns exist in the code, dependencies, and build steps?
  (3) is the publisher and supply chain trustworthy enough to run on
  this machine or against sensitive company data?
  Produces a verdict (install / sideload-with-caveats / do not install)
  with evidence, and when the audited tool fails, suggests a vetted
  local-only alternative from the official registry for that ecosystem.
  Use when the user pastes a GitHub URL, package name, or repo reference
  and asks "is this safe", "audit this", "review this repo", "does this
  leak data", "is this local-only", "before I install", "check this
  package/plugin/extension/module/image/SDK/binary", "should I trust
  this", "any malware in this", or any pre-install due-diligence framing.
  PROACTIVELY invoke (do not just answer "looks fine") when the user
  mentions adding any third-party dependency, installing a tool, cloning
  a repo to run, or pulling code that will execute on the device or read
  project files.
triggers:
  - audit this repo
  - audit this package
  - audit this plugin
  - is this safe to install
  - is this safe to use
  - is this safe to run
  - does this leak data
  - is this local-only
  - before I install
  - check this extension
  - check this package
  - review this repo
  - any malware
  - should I trust this
  - can I use this for
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - WebFetch
  - WebSearch
  - AskUserQuestion
  - Agent
---

# /audit-github-repo — Pre-Install Safety Audit (any language, any ecosystem)

**Iron rule:** never recommend "install" without confirming where data goes, what code runs, and what the supply chain looks like. "Open source" ≠ "safe." A 100-star MIT repo can POST your data to a cloud API on every render, run a postinstall script that mines crypto, or pull a malicious transitive dep that ships with a reverse shell. This skill is what makes the call.

## When to invoke

Trigger on any of:

- User pastes a GitHub URL or `owner/repo` reference and asks any safety / fitness question.
- User mentions installing a package (npm/pip/cargo/go/maven/gem/composer/NuGet/CocoaPods/SPM), an editor plugin (Obsidian, VSCode, JetBrains, Vim, Emacs, Sublime), a browser extension, a Claude Code plugin or MCP server, a Docker image, a Helm chart, a Terraform module, a mobile SDK, a kernel module, or a CLI tool — even if framed casually ("can I just `pip install` this").
- User considers a `git clone` of code that will be executed (build script, demo, dev tool).
- The tool will read company source code, customer or site data, telemetry, or any NDA-covered material.

**Skip** only when the artifact is already in an officially curated registry **and** the user has confirmed they accept that registry's review process. Curated = Obsidian community plugins, VSCode marketplace verified publisher, Chrome Web Store featured, JetBrains Marketplace verified, Claude Code plugin marketplace, official Linux distro repos. Open registries (npm / PyPI / cargo / Docker Hub / Maven Central) do **not** count — those publish anything.

## Two depths — pick before starting

| Depth | Time | When |
|---|---|---|
| **Quick** | ~3-5 min, no clone | Pre-install gut check, low-blast-radius tool, casual exploration |
| **Deep** | ~20-45 min, clone + scanners + sub-agent | Tool will run against company code or data, a customer environment, anything with secrets, anything that auto-loads on machine boot, OR the Quick pass surfaced a suspicious finding |

A Deep audit always starts with the Quick phases and adds Phase 4-deep + Phase 5-deep + a `security-reviewer` Opus delegation.

## Phases — one optional, six required

Run in order. Stop at the first phase that produces a "do not install" finding *unless* the user explicitly asks for the full picture.

### Phase 0 — Surface the whole repo (optional, local, ~10s)

`rendergit` flattens an entire repo into one static HTML page: syntax-highlighted human view, a CXML "LLM view" for one-shot delegation, and a **Skipped items** list naming every binary and oversized file it refused to render.

```bash
rendergit https://github.com/<owner>/<repo> --no-open -o /tmp/audit/<repo>.html
```

Why this belongs at the front of an audit: it converts "I'll fetch files one at a time and hope I picked the risky ones" into "I have the whole tree in front of me." Concretely it front-runs three later phases —

- **Phase 1** manifests (`package.json`, `setup.py`, `Cargo.toml`, `Dockerfile`) are all visible at once, so project shape is read, not guessed.
- **Phase 3** source-vs-artifact falls out immediately: a repo that ships only `dist/` bundles or only binaries is obvious on one page.
- **Depth choice** (Quick vs Deep) becomes evidence-based instead of a coin flip.

For a small repo this can replace the entire Quick-pass fetch sequence.

**Caveats — do not let this phase create false confidence:**

- Binaries and oversized files are **listed but not rendered**. A repo that ships a pre-compiled artifact still needs Phase 3 handling; the skipped list tells you it exists, not what it does.
- `rendergit` clones to a temp dir and **deletes it on exit**. A Deep audit still runs its own `git clone` (Phase 4) — greps, scanners, and the `security-reviewer` delegation all need files on disk with stable line numbers.
- It runs `git clone` against the target. That fetches code, it does not execute it, but for a repo already suspected malicious keep the output under `/tmp/audit/` and never point `-o` inside a project or the vault.
- Skip Phase 0 for very large repos (the page balloons) or when the repo is already on disk — for a local tree, Grep/Read beat a flattened page outright.

**Tooling status:** machine-local binary, `uv tool install git+https://github.com/karpathy/rendergit`, pinned at commit `14d7a58`. Source audited 2026-08-02: no telemetry, no `eval`/`exec`/`pickle`, `subprocess` calls use `shell=False`, sole network contact is the `git clone` of the target repo. **Upstream ships no LICENSE file** (all rights reserved), so it is installed per-machine and recorded in `manifests/binaries.json` — it is **not** vendored into `skills/` and must not be.

### Phase 1 — Identify

```bash
gh repo view <owner>/<repo> --json name,defaultBranchRef,licenseInfo,stargazerCount,pushedAt,description,isArchived,primaryLanguage,fork,parent
```

Capture: license, default branch (often `master`, not `main`), last push, star count, archived flag, primary language, fork status. Note `parent` if it's a fork — the question becomes "did the fork add anything the parent doesn't have?"

Then `gh api repos/<owner>/<repo>/contents/` to enumerate top-level files. Identify the project shape from manifest files:

| Manifest | Ecosystem |
|---|---|
| `package.json` | Node / npm / Electron / browser ext (also `manifest.json`) |
| `pyproject.toml`, `setup.py`, `requirements.txt`, `Pipfile` | Python |
| `Cargo.toml` | Rust |
| `go.mod` | Go |
| `pom.xml`, `build.gradle*` | Java / Kotlin / Android |
| `Gemfile`, `*.gemspec` | Ruby |
| `composer.json` | PHP |
| `*.csproj`, `*.sln`, `packages.config` | .NET |
| `Podfile`, `Package.swift` | Swift / iOS |
| `pubspec.yaml` | Dart / Flutter |
| `mix.exs` | Elixir |
| `Dockerfile`, `docker-compose.yml` | Container |
| `Chart.yaml`, `values.yaml` | Helm |
| `*.tf`, `terragrunt.hcl` | Terraform |
| `manifest.json` (with `permissions`) | Browser extension or Claude Code plugin |
| `mcp.json`, `.mcp.json` | MCP server |

Red flags: archived, last push > 18 months, fork from a deleted parent, no license, owner with < 5 public repos and no identity link, README written in a language the maintainer claims not to speak (translation supply-chain attacks).

### Phase 2 — Distribution channel & install vector

The install method is half the trust calculus. Bypassing review = yellow flag minimum.

| Channel | Trust | Verify with |
|---|---|---|
| Obsidian community plugins | High | `https://obsidian.md/plugins?search=<id>` |
| VSCode Marketplace verified publisher | High | Marketplace blue checkmark |
| JetBrains Marketplace verified | High | Plugin page badge |
| Chrome Web Store featured | High | Store featured badge |
| Claude Code plugin marketplace | High | `/plugin` browse |
| Distro packages (apt main, dnf, brew core) | High | Maintainer is the distro, not upstream |
| Microsoft Store, Mac App Store | High | Sandbox + review |
| F-Droid main repo | High | Reproducible-build verified |
| `pip install`, `npm install`, `cargo install`, `go install`, `gem`, `composer`, `nuget`, `pod`, `flutter pub` from public registry | **Yellow** | Registries don't vet for malicious behavior; check publisher + popularity + age |
| BRAT, manual sideload, JetBrains "install from disk" | **Yellow** | Bypasses store review |
| `git clone` + manual build | **Yellow** | Bypasses everything; build scripts run on your box |
| Pre-built binary release on GitHub | **Yellow-Red** | Cannot verify the binary matches the source unless reproducible builds + SLSA provenance present |
| `curl <url> \| bash` | **Red** | Hard refuse unless the user has read the script and pinned by SHA |

Always state the install vector explicitly in the verdict.

### Phase 3 — Source-vs-artifact reality check

Confirm the **real** source ships, not just a minified bundle, an obfuscated artifact, or pre-compiled binaries.

```bash
gh api repos/<owner>/<repo>/contents/src
gh api repos/<owner>/<repo>/contents/lib
gh api repos/<owner>/<repo>/contents/dist  # bundle-only smell
```

If only the bundle ships:
- Auditable in theory, not in practice. Note as a finding.
- The audit must continue against the bundle (Phases 4 still work on minified JS / stripped binaries with limits).

For binary releases: check whether `.sigstore`, `.intoto.jsonl`, or SLSA provenance is attached. Prefer signed releases. Verify with `gh attestation verify` when available.

### Phase 4 — Static analysis (the load-bearing phase)

This is what the user actually wants: every API call, every security flaw, every suspicious construct. Decide Quick vs Deep.

#### Quick (no clone)

Pull the highest-risk file directly via `gh api repos/.../contents/<path>` — the bundle, the entry point, the `setup.py`, the `Dockerfile`, etc. Save to `/tmp/audit/`. Run the Grep tool against it for the patterns below.

#### Deep (clone)

```bash
git clone --depth 1 https://github.com/<owner>/<repo>.git /tmp/audit/<repo>
```

Run this even if Phase 0 already rendered the repo — `rendergit` discards its clone, and greps, scanners, and the `security-reviewer` handoff all need real files with stable line numbers. Phase 0 tells you *where to look*; this clone is what you look at.

Now run all greps over the full tree. Optionally invoke external scanners if installed (`gitleaks detect`, `semgrep --config auto`, `trufflehog filesystem`).

#### Pattern catalog — language-agnostic core

| Concern | Severity if found | Notes |
|---|---|---|
| Hardcoded secrets (`AKIA[0-9A-Z]{16}`, `ghp_[A-Za-z0-9]{36}`, `sk-[A-Za-z0-9]{20,}`, `xox[baprs]-`, `eyJ[A-Za-z0-9_-]{20,}\.`, `-----BEGIN (RSA\|EC\|OPENSSH\|PGP) PRIVATE KEY-----`) | High | Even if "test" keys; rotate-on-discovery rule |
| Reverse-shell signatures (`bash -i >& /dev/tcp/`, `nc -e`, `python -c .*socket\.socket`, `ncat --exec`) | Critical | Hard refuse |
| Cryptominer signatures (`xmrig`, `stratum\+tcp://`, `cryptonight`, `monero`, `coinhive`) | Critical | Hard refuse |
| Auto-update fetch-and-exec (downloads code at runtime then `eval`/`exec`/`Function`/imports it) | High-Critical | Lifelong RCE — code can change post-install |
| Long base64 blobs (>500 chars in source) | Suspicious | Decode and investigate |
| Long hex blobs (>500 chars) | Suspicious | Decode and investigate |
| String concatenation building URLs from runtime input + fetch | High | Possible SSRF or remote-config supply chain |
| Telemetry / analytics endpoints not disclosed in README | Medium-High | Privacy finding |
| Disabled TLS verification (`rejectUnauthorized: false`, `verify=False`, `InsecureSkipVerify`, `-k`) | Medium-High | MITM risk + can hide exfil to attacker server |

#### Pattern catalog — per-language quick reference

Grep these in parallel. Each row is one language family.

| Language | Outbound network | Dynamic exec | Process spawn | Env / secret read | FS access |
|---|---|---|---|---|---|
| **JS/TS** (Node, Electron, browser) | `fetch\(`, `axios`, `XMLHttpRequest`, `WebSocket\(`, `https?\.(get\|request)`, `node-fetch`, `got\(`, `superagent`, `navigator\.sendBeacon` | `eval\(`, `new Function`, `vm\.runIn`, `setTimeout\(['"\`]`, `setInterval\(['"\`]`, `import\(.*\$\{` | `child_process`, `\.spawn\(`, `\.exec\(`, `execSync`, `fork\(` | `process\.env`, `process\.platform`, `os\.userInfo` | `fs\.(read\|write)`, `fs\.promises`, `path\.join.*home` |
| **Python** | `requests\.`, `httpx\.`, `urllib`, `aiohttp`, `socket\.`, `urllib3`, `pycurl`, `websockets` | `eval\(`, `exec\(`, `compile\(`, `pickle\.loads?`, `yaml\.load[^_]`, `marshal\.loads`, `__import__\(`, `importlib\.import_module` | `subprocess\.`, `os\.system`, `os\.popen`, `os\.exec`, `Popen` | `os\.environ`, `os\.getenv`, `getpass\.` | `open\(`, `pathlib`, `shutil\.copy`, `~/\.\w+` |
| **Go** | `http\.(Get\|Post\|Do)`, `net\.Dial`, `grpc\.Dial`, `websocket\.Dialer` | `reflect\.`, `unsafe\.`, `plugin\.Open` | `exec\.Command`, `syscall\.(Exec\|StartProcess)` | `os\.Getenv`, `os\.LookupEnv` | `os\.(Open\|Create\|ReadFile\|WriteFile)`, `ioutil\.` |
| **Rust** | `reqwest`, `hyper`, `surf`, `ureq`, `tokio::net`, `actix_web::client` | `unsafe ` block, `std::mem::transmute`, `libloading::Library` | `std::process::Command`, `Stdio` | `std::env::var`, `std::env::vars` | `std::fs::`, `tokio::fs::` |
| **Java/Kotlin** | `HttpClient`, `URLConnection`, `OkHttp`, `RestTemplate`, `WebClient`, `Socket\(` | `Runtime\.getRuntime\(\)\.exec`, `ScriptEngine`, `Class\.forName`, `MethodHandle`, `Unsafe` | `ProcessBuilder`, `Runtime\.exec` | `System\.getenv`, `System\.getProperty` | `Files\.(read\|write)`, `FileInputStream`, `RandomAccessFile` |
| **C / C++** | `curl_easy_`, `socket\(`, `connect\(`, `send\(`, `recv\(`, `getaddrinfo` | `dlopen\(`, `dlsym\(`, `mmap.*PROT_EXEC`, inline assembly | `fork\(`, `exec[lv]p?\(`, `system\(`, `popen\(` | `getenv\(`, `secure_getenv` | `fopen\(`, `open\(`, `mmap\(`, `creat\(` |
| **Ruby** | `Net::HTTP`, `open-uri`, `HTTParty`, `Faraday`, `RestClient`, `TCPSocket` | `eval`, `instance_eval`, `class_eval`, `binding\.eval`, `Marshal\.load`, `YAML\.load[^_]` | `system\(`, `exec\(`, `` ` ``, `Open3`, `IO\.popen` | `ENV\[`, `ENV\.fetch` | `File\.(read\|write\|open)`, `FileUtils` |
| **PHP** | `curl_exec`, `file_get_contents.*http`, `fsockopen`, `stream_socket_client`, `Guzzle` | `eval\(`, `assert\(`, `create_function\(`, `unserialize\(`, `\$\$\w+`, ``backtick`` | `system\(`, `exec\(`, `shell_exec\(`, `passthru\(`, `popen\(`, `proc_open` | `getenv\(`, `\$_ENV`, `\$_SERVER` | `fopen\(`, `file_put_contents`, `move_uploaded_file` |
| **C# / .NET** | `HttpClient`, `WebClient`, `WebRequest`, `Socket`, `TcpClient`, `RestSharp` | `Assembly\.Load`, `Activator\.CreateInstance`, `CSharpScript`, `Reflection\.Emit`, `dynamic ` | `Process\.Start`, `ProcessStartInfo` | `Environment\.GetEnvironmentVariable` | `File\.(Read\|Write)`, `FileStream`, `StreamWriter` |
| **Swift / Objective-C** | `URLSession`, `NSURLConnection`, `Network\.framework`, `Alamofire` | `NSClassFromString`, `dlsym`, `objc_msgSend` with dynamic selectors | `Process\(\)`, `posix_spawn` | `ProcessInfo\.processInfo\.environment`, `getenv` | `FileManager`, `FileHandle` |
| **Shell / Bash** | `curl`, `wget`, `nc `, `/dev/tcp/`, `ssh `, `scp `, `rsync ` | `eval `, `source `, `\. `, `\$\(\$.*\)` (nested cmd subst) | direct command, `xargs ... bash` | `\$\{?\w*PASSWORD`, `\$\{?\w*TOKEN`, `\$\{?\w*KEY` | `>` redirects, `tee`, `dd ` |
| **Docker / OCI** | `RUN curl`, `RUN wget`, `ADD https?://`, `ADD git@` (silently fetches!) | `RUN bash -c .*\$\(`, multi-stage with downloaded build tools | `RUN` itself runs as root | `ARG`, `ENV` propagation; `--build-arg` secrets | volume mounts widening scope |
| **Terraform / IaC** | `http` data source, `external` data source running scripts | `templatefile` with `${...}` injection | `local-exec`, `remote-exec` provisioners | `var.*` reading sensitive vars | `local_file` writes |

#### Special-channel checks

- **Browser extensions** — open `manifest.json`. Audit `permissions`, `host_permissions`, `content_scripts.matches`, `web_accessible_resources`, `externally_connectable`. Flag wildcard `<all_urls>` and `*://*/*`.
- **Claude Code plugins / MCP servers** — read the manifest and any subagent definitions. Check `allowed-tools`, hostnames in the MCP server, and whether agents make external calls. Confirm the plugin doesn't quietly add hooks to `~/.claude/settings.json`.
- **VSCode extensions** — `package.json` `activationEvents` (auto-run-on-startup is an attack surface), `contributes.commands`, `extensionDependencies`.
- **Mobile SDKs** — Android `AndroidManifest.xml` permissions; iOS `Info.plist` `NSAppTransportSecurity`, `NSCameraUsageDescription`, etc.
- **Kernel modules / native code** — refuse without a Deep audit and a `security-reviewer` Opus pass. Kernel-space code is a different threat tier.

#### Delegate the deep dive

For Deep audits or whenever a Quick pass found anything ambiguous, hand the `/tmp/audit/<repo>` directory to `security-reviewer` on Opus:

```
Agent({
  description: "Deep audit of <owner>/<repo>",
  subagent_type: "security-reviewer",
  model: "opus",
  prompt: "Inspect /tmp/audit/<repo>. Look for: dynamic-eval and reflection patterns, base64/hex-encoded payloads that decode to URLs or executable code, obfuscated network calls, persistence mechanisms (cron, systemd, launchd, Windows registry, login items, scheduled tasks), child_process spawns with user-influenced args, file writes outside the package's expected scope, env-var enumeration that exfils to network calls, postinstall/preinstall lifecycle scripts, divergence from the README's stated data flow, known-bad package signatures (event-stream, flatmap-stream, ua-parser-js 0.7.29-0.7.31, colors.js 1.4.1+, node-ipc 11.0.0+, xz utils 5.6.0-5.6.1), typosquat indicators, and anything that runs at install time. Report findings with severity (critical/high/medium/low) and concrete file:line references."
})
```

### Phase 5 — Supply chain

The repo's own code is one risk. Its dependency graph is usually larger.

#### Lockfile review

For Deep audits, parse the lockfile. Goal: enumerate transitive deps and flag anything unexpected.

| Ecosystem | Lockfile | Native audit tool |
|---|---|---|
| npm / yarn / pnpm | `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml` | `npm audit --json`, `pnpm audit --json` |
| Python | `poetry.lock`, `Pipfile.lock`, `requirements.txt` (pinned) | `pip-audit`, `safety check` |
| Rust | `Cargo.lock` | `cargo audit` |
| Go | `go.sum` + `go.mod` | `govulncheck ./...` |
| Java/Kotlin | `gradle.lockfile`, Maven dependency tree | `dependency-check`, OSS Index |
| Ruby | `Gemfile.lock` | `bundler-audit check --update` |
| PHP | `composer.lock` | `composer audit` |
| .NET | `packages.lock.json` | `dotnet list package --vulnerable` |
| Container | image digest + base image | `trivy image`, `grype` |

If none of the audit tools are installed locally, fall back to GitHub's advisory database:

```bash
gh api graphql -f query='
{ securityVulnerabilities(first:100, ecosystem:NPM, package:"<name>") {
    nodes { advisory { ghsaId severity summary } vulnerableVersionRange firstPatchedVersion { identifier } } } }
'
```

#### Lifecycle / install-time scripts

| Ecosystem | Where install-time code can run |
|---|---|
| npm | `package.json` `scripts.preinstall`, `install`, `postinstall` |
| pip | `setup.py` (executes on install), `pyproject.toml` build hooks |
| cargo | `build.rs` |
| gem | `extconf.rb` |
| composer | `scripts.post-install-cmd`, `post-update-cmd` |
| Go | none at install time (compile-only) — relatively safer |
| Rust | `build.rs` runs at build, not install — but still arbitrary code |

These run with user privileges on the install machine. Always grep them. **Postinstall + network call = high suspicion.**

#### Supply-chain attack signatures

A non-exhaustive list of historical attacks; full catalog in `reference.md`. Quick checks:

- `event-stream` ≥ 3.3.6 — embeds `flatmap-stream`
- `ua-parser-js` 0.7.29 / 0.8.0 / 1.0.0 — coinminer + credential stealer
- `colors.js` 1.4.1+, `faker.js` 6.6.6 — sabotage commits
- `node-ipc` 11.0.0+ — geo-targeted file wipe (protestware)
- `xz utils` 5.6.0–5.6.1 — sshd backdoor (CVE-2024-3094)
- `ctx` (PyPI) — replaced with credential stealer in 2022
- `discord.dll`, `discord-selfbot-v14`, etc. — typosquat malware family
- `web3.js` 1.x with `@solana/web3.js` 1.95.6/1.95.7 — supply-chain attack 2024

If the audited repo depends on any of these versions, refuse install.

#### Typosquat / namesquat

Check the repo or package name against well-known names. `electon` vs `electron`, `requets` vs `requests`, `crossenv` vs `cross-env`, `loadyaml` vs `pyyaml`. If close to a popular name and recently published, refuse pending verification.

### Phase 6 — Trust signals + verdict + alternative

Trust signals are weak priors, not proof:

- ✅ License is permissive or copyleft and source is published in full
- ✅ Maintainer has a public identity (company website, verified GitHub, prior reputation in the ecosystem)
- ✅ Active issues with substantive maintainer responses
- ✅ Recent commits in the last 6 months
- ✅ Releases signed (Sigstore, GPG, SLSA provenance)
- ⚠️ Single-maintainer + funding via crypto only
- ⚠️ Many forks, but the original is archived
- ❌ Maintainer username < 30 days old + thousands of stars (botted or paid)

If Phase 4 or 5 produces a "do not install" finding, search the same registry for a vetted local-only alternative *before* delivering the verdict. Apply Phases 1-4 to the alternative.

## Verdict format

End the audit with this block. No fluff, just findings.

```
## Audit verdict: <owner>/<repo>

**Install vector:** <registry / sideload / clone+build / curl|bash>
**Trust signals:** <license · stars · last push · registry status · provenance>
**Source published:** <full / partial / bundle-only / binary-only>
**Data egress:** <local-only | endpoints listed below | YES — to <hostnames>>
**Security findings:** <none | N findings, severity X — listed below>
**Supply chain:** <clean / N vulnerable deps / install-time scripts noted>
**Recommendation:** <install / sideload-with-caveats / do not install>

Endpoints contacted at runtime:
- <host> — <purpose, from README or grep>

Security findings (if any):
- [SEVERITY] <file:line> — <one-line description>

Local-only alternative (if applicable):
- <repo or registry link> — <why it fits>
```

User-facing report should be under ~250 words for a Quick audit, under ~500 for Deep. Findings, then verdict, then alternative — no per-phase headers in the *output*; those structure the *work*.

## Company data sensitivity

On a work machine the code and data belong to the company. Defaults shift:

- **Default to "do not install"** if Phase 4 shows egress to any third party (including LLM vendors or analytics).
- A local-only tool is always preferred even when the cloud version is more capable.
- Anything new goes through the company's own approval or vetting process first. This audit supports that process, it does not replace it.
- If a cloud tool is necessary, sandbox it against non-company test content.
- For any tool with native code, install-time scripts, or kernel access, a Deep audit is mandatory.

## Anti-patterns

- "It's open source, so it's fine." Open source ≠ local-only ≠ malware-free. Audit the artifact.
- "It has 5k stars, must be safe." `event-stream` had millions of weekly downloads when it was compromised. Stars measure popularity, not hygiene.
- "The README says it's privacy-respecting." The bundle and the lockfile are the source of truth. Confirm with grep.
- "I'll just `pip install` it real quick." `setup.py` runs on install. So does `postinstall`. So does `build.rs`. Audit before, not after.
- Grading on a curve because a tool is "useful" — useful and unsafe are independent axes.
- Treating a clean Phase 0 render as a clean audit. `rendergit` shows you what is *there*; it says nothing about what the code *does*. The files it skips are binaries — often the highest-risk artifacts in the repo, and precisely the ones it will not show you.
- Rerunning the audit from scratch every chat — if you audited it yesterday and the SHA hasn't changed, cite the prior verdict.

## Output discipline & progressive disclosure

- Quick audit output: under 250 words, verdict-first.
- Deep audit output: under 500 words + linked findings. Long evidence belongs in a saved audit doc, not in chat.
- For language-specific deep patterns, the historical supply-chain attack catalog, full secret-regex library, and channel-by-channel verification details, load `reference.md` from this skill folder. **Do not load it for Quick audits** — it's only worth the tokens when going deep.
