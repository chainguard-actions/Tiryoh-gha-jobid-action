<!-- markdownlint-disable -->

# Hardening Report: Tiryoh--gha-jobid-action/v1.3.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **Tiryoh--gha-jobid-action/v1.3.0** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### suspicious-run-content (severity: high)

eval-dynamic: The run block uses `eval "$(...)"` (eval with command substitution) to execute shell code derived from a GitHub API response. Specifically: `eval "$(echo "${JOBINFO}" | jq -r --arg job_name "${INPUT_JOB_NAME}" '.jobs | map(select(.name == $job_name)) | .[0] | @sh "JOB_ID=\(.id) HTML_URL=\(.html_url)"')"`. While jq's @sh attempts to quote the output, using eval on externally-sourced data is a dangerous pattern that can execute arbitrary shell commands if the API response is malformed or attacker-influenced.

Locations:

- `action.yml:45`

### github-env-injection (severity: high)

The variables JOB_ID and HTML_URL are populated via eval of a GitHub API response and then written directly to $GITHUB_OUTPUT without the required sanitization step (printf '%s' ... | tr -d '\n\r'). If the API response contains embedded newlines, an attacker could inject additional key=value pairs into GITHUB_OUTPUT. Lines: `echo "job_id=${JOB_ID}" >> "$GITHUB_OUTPUT"` and `echo "html_url=${HTML_URL}" >> "$GITHUB_OUTPUT"`.

Locations:

- `action.yml:47`
- `action.yml:48`

## Iteration Notes

### Iteration 1

**Fixes applied:** suspicious-run-content, github-env-injection

**Notes:**

Fixed action.yml in two ways: (1) Replaced the dangerous `eval "$(... | jq -r ... @sh ...)"` pattern with two direct jq field extractions (`JOB_ID=$(... | jq -r '... | .id')` and `HTML_URL=$(... | jq -r '... | .html_url')`), eliminating the eval-of-external-data risk entirely. (2) Added sanitization of both values using `printf '%s' "${VAR}" | tr -d '\n\r'` before writing to $GITHUB_OUTPUT, preventing newline injection attacks.

