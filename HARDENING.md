<!-- markdownlint-disable -->

# Hardening Report: Tiryoh--gha-jobid-action/v1.4.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Tiryoh--gha-jobid-action/v1.4.0** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The composite step 'Parse job_id' writes JOB_ID and HTML_URL to $GITHUB_OUTPUT with `echo "job_id=${JOB_ID}" >> "$GITHUB_OUTPUT"` and `echo "html_url=${HTML_URL}" >> "$GITHUB_OUTPUT"`. Neither value is sanitized first. Both come from an API response that the step fetches using workflow-controlled inputs (inputs.repository, inputs.run_id, inputs.per_page) and filters by inputs.job_name. The step never strips newlines (`printf '%s' ... | tr -d '\n\r'`) before the write, so if a value contains a newline it can add extra output entries.

Locations:

- `action.yml:54`
- `action.yml:55`

### prior-fix (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. The previous harden changed action.yml without recording a finding for it, and this analysis reported nothing there. Re-apply its security changes unless the code no longer needs them. The previous patch:
```diff
diff --git a/action.yml b/action.yml
index 92ee3b1..3991423 100644
--- a/action.yml
+++ b/action.yml
@@ -27,14 +27,29 @@ outputs:
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

```

Locations:

- `action.yml`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, prior-fix

**Notes:**

In action.yml, JOB_ID and HTML_URL now have newlines and carriage returns stripped with printf | tr -d '\n\r' before they are written to $GITHUB_OUTPUT. I also re-applied the previous harden's patch. It only removed blank lines and changes no behaviour.

