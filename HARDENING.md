<!-- markdownlint-disable -->

# Hardening Report: Tiryoh--gha-jobid-action/v1.3.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Tiryoh--gha-jobid-action/v1.3.0** was hardened automatically. 5 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

Workflow files reference actions by mutable tag (@v4) rather than a pinned 40-character commit SHA. This exposes the workflow to supply-chain attacks if the tag is moved. Affected references: `actions/checkout@v4` in test.yaml (4 occurrences) and `actions/checkout@v4` in version-tag.yaml (1 occurrence).

Locations:

- `.github/workflows/test.yaml:18`
- `.github/workflows/test.yaml:56`
- `.github/workflows/test.yaml:95`
- `.github/workflows/test.yaml:134`
- `.github/workflows/version-tag.yaml:9`

### missing-permissions (severity: medium)

Neither workflow file defines a top-level `permissions:` block, and no individual job defines its own `permissions:` block. Without explicit permissions, the GITHUB_TOKEN is granted its default (broad) permissions, violating the principle of least privilege.

Locations:

- `.github/workflows/test.yaml:1`
- `.github/workflows/version-tag.yaml:1`

### script-injection (severity: high)

Rule (a): GitHub Actions expressions are interpolated directly inside `run:` shell command strings, allowing an attacker to inject arbitrary shell commands. In test.yaml, `${{ steps.test1.outputs.html_url }}`, `${{ steps.test1.outputs.job_id }}`, `${{ steps.test2.outputs.html_url }}`, etc. are embedded directly in shell `run:` blocks (e.g. `check_url "${{ steps.test1.outputs.html_url }}" "..."`). In version-tag.yaml, `${{ secrets.GITHUB_TOKEN }}` is interpolated directly in a `run:` block: `git remote set-url origin https://${{ secrets.GITHUB_TOKEN }}@github.com/...`.

Locations:

- `.github/workflows/test.yaml:36`
- `.github/workflows/test.yaml:75`
- `.github/workflows/test.yaml:114`
- `.github/workflows/version-tag.yaml:11`

### suspicious-run-content (severity: high)

eval-dynamic: The `run:` block in action.yml uses `eval "$(...)"` — eval with command substitution — to execute dynamically constructed shell commands derived from API response data processed through jq. The offending line is: `eval "$(echo "${JOBINFO}" | jq -r --arg job_name "${INPUT_JOB_NAME}" '.jobs | map(select(.name == $job_name)) | .[0] | @sh "JOB_ID=\(.id) HTML_URL=\(.html_url)"')"`. If the API response or job_name input contains malicious content, this could lead to arbitrary command execution.

Locations:

- `action.yml:46`

### github-env-injection (severity: high)

The `run:` block in action.yml writes `${JOB_ID}` and `${HTML_URL}` to `$GITHUB_OUTPUT` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). These variables are populated via `eval "$(... jq ... @sh ...)"` from external API response data and the caller-controlled `INPUT_JOB_NAME` input. A newline embedded in these values could allow injection of additional key=value pairs into GITHUB_OUTPUT. The offending lines are: `echo "job_id=${JOB_ID}" >> "$GITHUB_OUTPUT"` and `echo "html_url=${HTML_URL}" >> "$GITHUB_OUTPUT"`.

Locations:

- `action.yml:48`
- `action.yml:49`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, missing-permissions, script-injection, suspicious-run-content, github-env-injection

**Notes:**

Fixed all 5 findings across 3 files:

1. action.yml: Replaced eval+@sh pattern with direct jq field extraction (.id and .html_url) to eliminate arbitrary command execution risk. Added printf/tr sanitization before writing JOB_ID and HTML_URL to $GITHUB_OUTPUT to prevent newline injection.

2. .github/workflows/test.yaml: Pinned actions/checkout@v4 to SHA 11d5960a326750d5838078e36cf38b85af677262. Added top-level `permissions: contents: read`. Moved all ${{ steps.testN.outputs.* }} expressions from run: blocks into env: blocks, referencing them as plain shell variables.

3. .github/workflows/version-tag.yaml: Pinned actions/checkout@v4 to SHA 11d5960a326750d5838078e36cf38b85af677262. Added top-level `permissions: contents: write` (needed to push tags). Moved ${{ secrets.GITHUB_TOKEN }} and ${{ github.ref }} from the run: block into the env: block.

