<!-- markdownlint-disable -->

# Hardening Report: Tiryoh--gha-jobid-action/v1.3.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Tiryoh--gha-jobid-action/v1.3.0** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The composite step 'Parse job_id' (id: request) writes JOB_ID and HTML_URL to $GITHUB_OUTPUT with `echo "job_id=${JOB_ID}" >> "$GITHUB_OUTPUT"` and `echo "html_url=${HTML_URL}" >> "$GITHUB_OUTPUT"`, and nothing strips newlines first. Both values are parsed from an API response. The request is built from workflow-controlled inputs: inputs.repository, inputs.run_id, inputs.per_page, github.api_url (GITHUB_BASEURL) and the inherited GITHUB_REPOSITORY/GITHUB_RUN_ID. If the response holds newlines, extra output lines can be injected. Fix: pass each value through `printf '%s' "$VAR" | tr -d '\n\r'` right before writing it.

Locations:

- `action.yml:51`
- `action.yml:52`

### suspicious-run-content (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. eval-dynamic: The `run:` block in action.yml uses `eval "$(...)"` — eval with command substitution — to execute dynamically constructed shell commands derived from API response data processed through jq. The offending line is: `eval "$(echo "${JOBINFO}" | jq -r --arg job_name "${INPUT_JOB_NAME}" '.jobs | map(select(.name == $job_name)) | .[0] | @sh "JOB_ID=\(.id) HTML_URL=\(.html_url)"')"`. If the API response or job_name input contains malicious content, this could lead to arbitrary command execution.

Locations:

- `action.yml:46`

### prior-fix (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. The previous harden changed action.yml without recording a finding for it, and this analysis reported nothing there. Re-apply its security changes unless the code no longer needs them. The previous patch:
```diff
diff --git a/action.yml b/action.yml
index 0282995..2860a05 100644
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
@@ -46,7 +61,10 @@ runs:
         JOBINFO="$(curl --get -Ss -H "Authorization: Bearer ${INPUT_GITHUB_TOKEN}" -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" "${GITHUB_BASEURL}${GITHUB_API}?per_page=${INPUT_PER_PAGE:-30}")"
         echo "${JOBINFO}" | grep "Resource not accessible by integration" &&  exit 1
         TOTAL_COUNT="$(echo "${JOBINFO}" | jq -r .total_count)"
-        eval "$(echo "${JOBINFO}" | jq -r --arg job_name "${INPUT_JOB_NAME}" '.jobs | map(select(.name == $job_name)) | .[0] | @sh "JOB_ID=\(.id) HTML_URL=\(.html_url)"')"
+        JOB_ID="$(echo "${JOBINFO}" | jq -r --arg job_name "${INPUT_JOB_NAME}" '.jobs | map(select(.name == $job_name)) | .[0] | .id')"
+        HTML_URL="$(echo "${JOBINFO}" | jq -r --arg job_name "${INPUT_JOB_NAME}" '.jobs | map(select(.name == $job_name)) | .[0] | .html_url')"
         echo "${JOB_ID}" | grep "null" > /dev/null && echo "parse error, job_id is ${JOB_ID} and total_count is ${TOTAL_COUNT}. 'job_name' or 'per_page' might be wrong. See https://github.com/Tiryoh/gha-jobid-action/blob/main/README.md#inputs" && exit 1
-        echo "job_id=${JOB_ID}" >> "$GITHUB_OUTPUT"
-        echo "html_url=${HTML_URL}" >> "$GITHUB_OUTPUT"
+        safe_job_id="$(printf '%s' "${JOB_ID}" | tr -d '\n\r')"
+        safe_html_url="$(printf '%s' "${HTML_URL}" | tr -d '\n\r')"
+        echo "job_id=${safe_job_id}" >> "$GITHUB_OUTPUT"
+        echo "html_url=${safe_html_url}" >> "$GITHUB_OUTPUT"

```

Locations:

- `action.yml`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, suspicious-run-content, prior-fix

**Notes:**

I made both changes in action.yml. First, I removed the `eval` of the shell code that jq built. JOB_ID and HTML_URL are now read straight from the API response with two separate `jq -r` calls. This gives the same values as before, and an empty match still gives the string 'null', so the null check works as it did. Second, both values now have newlines and carriage returns stripped (`printf '%s' | tr -d '\n\r'`) right before they are written to $GITHUB_OUTPUT. This puts back the previous harden's patch. I didn't run the action to test it.

