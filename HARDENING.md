<!-- markdownlint-disable -->

# Hardening Report: Tiryoh--gha-jobid-action/v1.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **Tiryoh--gha-jobid-action/v1.0.0** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### suspicious-run-content (severity: high)

eval-dynamic: The run block uses `eval "$(echo ${JOBINFO} | jq -r ...)"` — eval with $() command substitution on data derived from an external API response. This matches the eval-dynamic pattern and can execute arbitrary shell commands if the API response is manipulated.

Locations:

- `action.yml:44`

### script-injection (severity: high)

Rule (b): Unquoted shell variable expansions of untrusted data. `echo ${JOBINFO}` is unquoted — JOBINFO contains the raw curl API response influenced by input-derived env vars (INPUT_REPOSITORY, INPUT_RUN_ID). `echo ${job_id}` is also unquoted — job_id is set via eval from the API response. Unquoted expansions allow shell metacharacter injection.

Locations:

- `action.yml:43`

### github-env-injection (severity: high)

The run block writes `job_id` and `html_url` to $GITHUB_OUTPUT without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). These values are set via `eval` from API response data (influenced by inputs.job_name and the GitHub API), and could contain newlines that inject additional key=value pairs into GITHUB_OUTPUT.

Locations:

- `action.yml:46`

## Iteration Notes

### Iteration 1

**Fixes applied:** suspicious-run-content, script-injection, github-env-injection

**Notes:**

Fixed action.yml run block: (1) Replaced dangerous `eval "$(echo ${JOBINFO} | jq -r ...)"` with safe direct jq field extraction using `.id` and `.html_url` selectors assigned to variables without eval. (2) Quoted all variable expansions (`"${JOBINFO}"`, `"${job_id}"`, etc.) and used `printf '%s'` instead of unquoted `echo ${JOBINFO}` to prevent shell metacharacter injection. (3) Added sanitization step using `printf '%s' ... | tr -d '\n\r'` for both `job_id` and `html_url` before writing to `$GITHUB_OUTPUT`, and quoted `"$GITHUB_OUTPUT"` in the redirection.

