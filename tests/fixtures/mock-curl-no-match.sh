#!/bin/bash
# Mock curl: return a jobs list with a job that does NOT match the requested name
echo '{"total_count":1,"jobs":[{"id":12345,"name":"some-other-job","html_url":"https://github.com/owner/repo/actions/runs/1/jobs/12345"}]}'
