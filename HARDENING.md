<!-- markdownlint-disable -->

# Hardening Report: Tiryoh--gha-jobid-action/v1.2.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **Tiryoh--gha-jobid-action/v1.2.0** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### suspicious-run-content (severity: high)

eval-dynamic: The run block in action.yml uses `eval "$(echo ${JOBINFO} | jq ...)"` — eval with command substitution (`$(...)`) of data derived from an external API response. This matches the eval-dynamic pattern (`eval\s+[\x60$]`) and can execute arbitrary shell commands if the API response is manipulated.

Locations:

- `action.yml:44`

### github-env-injection (severity: high)

The run block writes `JOB_ID` and `HTML_URL` to `$GITHUB_OUTPUT` without sanitization. These variables are populated via `eval` from external API response data (which is itself derived from workflow inputs such as `inputs.job_name`, `inputs.repository`, `inputs.run_id`). No `printf '%s' ... | tr -d '\n\r'` sanitization is applied before the writes: `echo "job_id=${JOB_ID}" >> $GITHUB_OUTPUT` and `echo "html_url=${HTML_URL}" >> $GITHUB_OUTPUT`.

Locations:

- `action.yml:46`
- `action.yml:47`

### script-injection (severity: high)

Sub-rule (b): Multiple env vars holding workflow-controllable inputs are used unquoted in the run block shell commands. For example: `${INPUT_REPOSITORY}`, `${INPUT_RUN_ID}`, `${INPUT_PER_PAGE}`, and `${JOBINFO}` (in the eval line) are all expanded without double-quoting, allowing shell metacharacter injection. Specifically: `GITHUB_API="/repos/${INPUT_REPOSITORY:-${GITHUB_REPOSITORY}}/actions/runs/${INPUT_RUN_ID:-${GITHUB_RUN_ID}}/jobs"` and `eval "$(echo ${JOBINFO} | jq -r --arg job_name \"${INPUT_JOB_NAME}\" ...)"` use unquoted expansions of untrusted inputs.

Locations:

- `action.yml:40`
- `action.yml:44`

## Iteration Notes

### Iteration 1

**Fixes applied:** suspicious-run-content, github-env-injection, script-injection

**Notes:**

Fixed action.yml run block: (1) Replaced dangerous `eval "$(echo ${JOBINFO} | jq ...)"` with direct jq field extraction (`.id` and `.html_url`) to eliminate eval-dynamic risk. (2) Added `printf '%s' ... | tr -d '\n\r'` sanitization for JOB_ID and HTML_URL before writing to $GITHUB_OUTPUT, and quoted the $GITHUB_OUTPUT variable. (3) Ensured all variable expansions (${JOBINFO}, ${JOB_ID}, ${HTML_URL}) are properly double-quoted throughout the run block.

