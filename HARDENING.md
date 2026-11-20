<!-- markdownlint-disable -->

# Hardening Report: Tiryoh--gha-jobid-action/v1.2.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Tiryoh--gha-jobid-action/v1.2.0** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The 'Parse job_id' step writes JOB_ID and HTML_URL to $GITHUB_OUTPUT without first running printf '%s' ... | tr -d '\n\r'. Both values come from a GitHub API response, and the caller picks which response through inputs.repository, inputs.run_id and inputs.job_name. Lines: echo "job_id=${JOB_ID}" >> $GITHUB_OUTPUT and echo "html_url=${HTML_URL}" >> $GITHUB_OUTPUT. A value containing a newline could add extra output entries.

Locations:

- `action.yml:51`
- `action.yml:52`

### script-injection (severity: high)

Rule (b): workflow-controlled data is expanded without double quotes in the 'Parse job_id' step. Line 49: eval "$(echo ${JOBINFO} | jq ...)" leaves ${JOBINFO} unquoted. JOBINFO holds the API response, and inputs.repository, inputs.run_id and inputs.per_page decide which response that is. Line 50: echo ${JOB_ID} | grep "null" leaves ${JOB_ID} unquoted. Both should be quoted ("${JOBINFO}", "${JOB_ID}").

Locations:

- `action.yml:49`
- `action.yml:50`

### prior-fix (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. The previous harden changed action.yml without recording a finding for it, and this analysis reported nothing there. Re-apply its security changes unless the code no longer needs them. The previous patch:
```diff
diff --git a/action.yml b/action.yml
index e2961c4..38866f1 100644
--- a/action.yml
+++ b/action.yml
@@ -23,14 +23,29 @@ outputs:
   html_url:
     description: "html_url of target workflow jobs"
     value: ${{ steps.request.outputs.html_url }}
-
 branding:
   icon: "link"
   color: "blue"
-
 runs:
   using: 'composite'
   steps:
     - name: Parse job_id
       id: request
       env:
@@ -46,8 +61,10 @@ runs:
         JOBINFO="$(curl --get -Ss -H "Authorization: Bearer ${INPUT_GITHUB_TOKEN}" -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" "${GITHUB_BASEURL}${GITHUB_API}?per_page=${INPUT_PER_PAGE:-30}")"
         echo "${JOBINFO}" | grep "Resource not accessible by integration" &&  exit 1
         TOTAL_COUNT="$(echo "${JOBINFO}" | jq -r .total_count)"
-        eval "$(echo ${JOBINFO} | jq -r --arg job_name "${INPUT_JOB_NAME}" '.jobs | map(select(.name == $job_name)) | .[0] | @sh "JOB_ID=\(.id) HTML_URL=\(.html_url)"')"
-        echo ${JOB_ID} | grep "null" > /dev/null && echo "parse error, job_id is ${JOB_ID} and total_count is ${TOTAL_COUNT}. 'job_name' or 'per_page' might be wrong. See https://github.com/Tiryoh/gha-jobid-action/blob/main/README.md#inputs" && exit 1
-        echo "job_id=${JOB_ID}" >> $GITHUB_OUTPUT
-        echo "html_url=${HTML_URL}" >> $GITHUB_OUTPUT
-
+        JOB_ID="$(printf '%s' "${JOBINFO}" | jq -r --arg job_name "${INPUT_JOB_NAME}" '.jobs | map(select(.name == $job_name)) | .[0].id')"
+        HTML_URL="$(printf '%s' "${JOBINFO}" | jq -r --arg job_name "${INPUT_JOB_NAME}" '.jobs | map(select(.name == $job_name)) | .[0].html_url')"
+        echo "${JOB_ID}" | grep "null" > /dev/null && echo "parse error, job_id is ${JOB_ID} and total_count is ${TOTAL_COUNT}. 'job_name' or 'per_page' might be wrong. See https://github.com/Tiryoh/gha-jobid-action/blob/main/README.md#inputs" && exit 1
+        safe_job_id="$(printf '%s' "${JOB_ID}" | tr -d '\n\r')"
+        safe_html_url="$(printf '%s' "${HTML_URL}" | tr -d '\n\r')"
+        echo "job_id=${safe_job_id}" >> "$GITHUB_OUTPUT"
+        echo "html_url=${safe_html_url}" >> "$GITHUB_OUTPUT"

```

Locations:

- `action.yml`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection, prior-fix

**Notes:**

I re-applied the previous harden's changes to the 'Parse job_id' step in action.yml. Nothing was run or tested.

- **Script injection:** the `eval` of jq `@sh` output is gone. JOB_ID and HTML_URL are now read with two separate jq calls, each fed by `printf '%s' "${JOBINFO}"`. The `JOB_ID` null check now quotes the variable.
- **Output injection:** newlines and carriage returns are stripped from both values before they are written to `$GITHUB_OUTPUT`, and `$GITHUB_OUTPUT` itself is now quoted.
- **Behaviour:** should be unchanged. When no job matches, jq still prints `null`, so the existing parse-error check still catches it.

