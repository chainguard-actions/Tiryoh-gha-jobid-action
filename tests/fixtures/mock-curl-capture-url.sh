#!/bin/bash
# Mock curl: capture URL arguments and return a jobs list with no matching job
for arg in "$@"; do
  if echo "$arg" | grep -q "per_page="; then
    echo "$arg" > /tmp/curl_url_captured.txt
  fi
done
echo '{"total_count":1,"jobs":[{"id":77777,"name":"some-other-job","html_url":"https://github.com/owner/repo/actions/runs/1/jobs/77777"}]}'
