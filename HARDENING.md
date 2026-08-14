<!-- markdownlint-disable -->

# Hardening Report: Tiryoh--gha-jobid-action/v1.1.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Tiryoh--gha-jobid-action/v1.1.0** was hardened automatically. 5 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

All `uses:` references in the workflow files use a mutable tag (`@v4`) instead of a pinned 40-character SHA commit hash. This exposes the action to supply-chain attacks if the tag is moved. Failing references: `actions/checkout@v4` in test.yaml (3 occurrences) and version-tag.yaml (1 occurrence).

Locations:

- `.github/workflows/test.yaml:18`
- `.github/workflows/test.yaml:47`
- `.github/workflows/test.yaml:88`
- `.github/workflows/version-tag.yaml:11`

### script-injection (severity: high)

Rule (a): `${{ steps.test1.outputs.html_url }}` and `${{ steps.test1.outputs.job_id }}` (and test2/test3 variants) are interpolated directly inside `run:` shell command strings in the Verify steps of all three test jobs. `steps.*.outputs.*` values are workflow-controllable and flow through YAML template substitution before the shell sees them, enabling script injection. Offending lines include: `check_url "${{ steps.test1.outputs.html_url }}" ...` and `check_job_id "${{ steps.test1.outputs.job_id }}" ...`.

Locations:

- `.github/workflows/test.yaml:36`
- `.github/workflows/test.yaml:37`
- `.github/workflows/test.yaml:79`
- `.github/workflows/test.yaml:80`
- `.github/workflows/test.yaml:81`
- `.github/workflows/test.yaml:82`
- `.github/workflows/test.yaml:83`
- `.github/workflows/test.yaml:121`
- `.github/workflows/test.yaml:122`
- `.github/workflows/test.yaml:123`

### script-injection (severity: high)

Rule (a): `${{ secrets.GITHUB_TOKEN }}` is interpolated directly inside the `run:` shell command string: `git remote set-url origin https://${{ secrets.GITHUB_TOKEN }}@github.com/...`. Any expression inside a `run:` block is a script-injection risk regardless of context. Rule (b): The env var `TAG` (sourced from `${{ github.ref }}`) is used unquoted in the run block as `${TAG%.*.*}` and `${TAG%.*}`, allowing shell metacharacter injection from a tag-push event ref value.

Locations:

- `.github/workflows/version-tag.yaml:14`
- `.github/workflows/version-tag.yaml:15`
- `.github/workflows/version-tag.yaml:16`

### github-env-injection (severity: high)

In action.yml, the `job_id` and `html_url` shell variables (populated via `eval "$(echo ${JOBINFO} | jq -r ... @sh ...)"` from an external API response) are written directly to `$GITHUB_OUTPUT` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). An attacker-controlled API response or a job name containing newlines could inject arbitrary key-value pairs into the GitHub output environment file. Lines: `echo "job_id=${job_id}" >> $GITHUB_OUTPUT` and `echo "html_url=${html_url}" >> $GITHUB_OUTPUT`.

Locations:

- `action.yml:50`
- `action.yml:51`

### permissions (severity: medium)

Neither workflow file defines a `permissions:` key at the top level or at the job level. Without explicit permissions, workflows inherit the default repository permissions (which may be `write-all`), violating the principle of least privilege. Both test.yaml and version-tag.yaml are missing permissions declarations.

Locations:

- `.github/workflows/test.yaml:1`
- `.github/workflows/version-tag.yaml:1`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection, github-env-injection, permissions

**Notes:**

Fixed all 5 findings across 3 files:

1. **test.yaml**: Pinned all 3 `actions/checkout@v4` references to SHA `11d5960a326750d5838078e36cf38b85af677262 # v4`. Moved all `${{ steps.testN.outputs.html_url }}` and `${{ steps.testN.outputs.job_id }}` expressions into `env:` blocks (TEST1_HTML_URL, TEST1_JOB_ID, etc.) and referenced them as plain env vars in shell. Added `permissions: contents: read` at workflow level.

2. **version-tag.yaml**: Pinned `actions/checkout@v4` to SHA `11d5960a326750d5838078e36cf38b85af677262 # v4`. Moved `${{ secrets.GITHUB_TOKEN }}` into `env:` block as `GITHUB_TOKEN` and referenced as `${GITHUB_TOKEN}` in shell. Added double-quoting around `${TAG%.*.*}` and `${TAG%.*}` expansions. Added `permissions: contents: write` (required for pushing tags).

3. **action.yml**: Sanitized `job_id` and `html_url` shell variables before writing to `$GITHUB_OUTPUT` using `printf '%s' ... | tr -d '\n\r'` to prevent newline injection from attacker-controlled API responses.

