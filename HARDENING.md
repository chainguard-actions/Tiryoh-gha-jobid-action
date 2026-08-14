<!-- markdownlint-disable -->

# Hardening Report: Tiryoh--gha-jobid-action/v1.2.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Tiryoh--gha-jobid-action/v1.2.0** was hardened automatically. 5 finding(s) were identified and resolved across 3 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): A ${{ }} expression is interpolated directly inside a run: shell command string. In version-tag.yaml line 14, `${{ secrets.GITHUB_TOKEN }}` is embedded directly in the git remote set-url command. Even though secrets.GITHUB_TOKEN is not attacker-controlled, any ${{ ... }} inside a run: block is a script-injection risk because the value flows through YAML template substitution before the shell ever sees it. Additionally, sub-rule (b): the env var TAG (set from `${{ github.ref }}`) is expanded unquoted as `${TAG%.*.*}` and `${TAG%.*}` inside `$(basename ...)` on lines 15–16, allowing shell metacharacter injection from the ref value.

Locations:

- `.github/workflows/version-tag.yaml:14`
- `.github/workflows/version-tag.yaml:15`
- `.github/workflows/version-tag.yaml:16`

### script-injection (severity: high)

Sub-rule (a): ${{ steps.testN.outputs.html_url }} and ${{ steps.testN.outputs.job_id }} expressions from steps.*.outputs.* context are interpolated directly inside run: shell command strings in the Verify steps of all three test jobs (single-job-test, multi-jobs-test, multi-jobs-test-31). The steps.*.outputs.* context is listed as an untrusted/workflow-controllable source. Offending lines include: `check_url "${{ steps.test1.outputs.html_url }}" ...` and `check_job_id "${{ steps.test1.outputs.job_id }}" ...` repeated across all three Verify steps.

Locations:

- `.github/workflows/test.yaml:50`
- `.github/workflows/test.yaml:51`
- `.github/workflows/test.yaml:83`
- `.github/workflows/test.yaml:84`
- `.github/workflows/test.yaml:85`
- `.github/workflows/test.yaml:86`
- `.github/workflows/test.yaml:87`
- `.github/workflows/test.yaml:88`

### github-env-injection (severity: high)

In action.yml, the composite action writes JOB_ID and HTML_URL to $GITHUB_OUTPUT without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). These variables are populated via `eval "$(echo ${JOBINFO} | jq ...)"` from an external API response. The values could contain newlines that would allow injection of additional key=value pairs into GITHUB_OUTPUT. The writes on lines 49–50 (`echo "job_id=${JOB_ID}" >> $GITHUB_OUTPUT` and `echo "html_url=${HTML_URL}" >> $GITHUB_OUTPUT`) are not preceded by any sanitization.

Locations:

- `action.yml:49`
- `action.yml:50`

### unpinned-uses (severity: high)

Multiple `uses:` references pin to a mutable version tag (`@v4`) instead of an immutable 40-character commit SHA. This exposes the workflow to supply-chain attacks if the tag is moved. Failing references: `actions/checkout@v4` appears in test.yaml (three times, in each job's Checkout step) and in version-tag.yaml.

Locations:

- `.github/workflows/test.yaml:22`
- `.github/workflows/test.yaml:57`
- `.github/workflows/test.yaml:92`
- `.github/workflows/version-tag.yaml:11`

### missing-permissions (severity: medium)

Neither workflow file defines a top-level `permissions:` key, and no individual job within either file defines a `permissions:` key. Without explicit permissions, workflows run with the repository's default token permissions (which may be read/write), violating the principle of least privilege. Both test.yaml and version-tag.yaml are affected.

Locations:

- `.github/workflows/test.yaml:1`
- `.github/workflows/version-tag.yaml:1`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, unpinned-uses, missing-permissions

**Notes:**

Fixed all 5 findings across 3 files:

1. action.yml (github-env-injection): Added `printf '%s' ... | tr -d '\n\r'` sanitization for JOB_ID and HTML_URL before writing to $GITHUB_OUTPUT.

2. version-tag.yaml (script-injection): Moved `secrets.GITHUB_TOKEN` from inline shell string into env: block; quoted TAG variable expansions in basename calls. (unpinned-uses): Pinned actions/checkout@v4 to SHA 11d5960a326750d5838078e36cf38b85af677262. (missing-permissions): Added `permissions: contents: write` (needed to push tags).

3. test.yaml (script-injection): Moved all steps.*.outputs.html_url and steps.*.outputs.job_id expressions into env: blocks for all three Verify steps; referenced as plain env vars in shell. (unpinned-uses): Pinned all three actions/checkout@v4 references to SHA 11d5960a326750d5838078e36cf38b85af677262. (missing-permissions): Added `permissions: contents: read` at top level.

### Iteration 2

**Fixes applied:** suspicious-run-content

**Notes:**

Replaced the dangerous `eval "$(echo ${JOBINFO} | jq -r --arg job_name "${INPUT_JOB_NAME}" '... | @sh "JOB_ID=\(.id) HTML_URL=\(.html_url)"')"` pattern with two safe direct jq extractions:
  JOB_ID="$(printf '%s' "${JOBINFO}" | jq -r --arg job_name "${INPUT_JOB_NAME}" '.jobs | map(select(.name == $job_name)) | .[0].id')"
  HTML_URL="$(printf '%s' "${JOBINFO}" | jq -r --arg job_name "${INPUT_JOB_NAME}" '.jobs | map(select(.name == $job_name)) | .[0].html_url')"

This eliminates the eval+command-substitution pattern that could allow arbitrary code execution from attacker-influenced API response data or caller-supplied job_name input. The jq --arg parameter safely passes INPUT_JOB_NAME as a data value (not code), and the field values are extracted directly without being interpreted as shell commands.

### Iteration 3

**Fixes applied:** script-injection

**Notes:**

Fixed unquoted shell variable expansion on line 51 of hardened/action/action.yml. Changed `echo ${JOB_ID}` to `echo "${JOB_ID}"` to prevent shell metacharacter interpretation when the JOB_ID value (derived from an external API response) is expanded. This eliminates the potential for command injection via attacker-controlled content in the API response.

