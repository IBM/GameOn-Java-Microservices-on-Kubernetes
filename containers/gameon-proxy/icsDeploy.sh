#!/bin/bash
git_retry clone https://github.com/gameontext/ics-pipeline-utilities.git pipeline_utils

pipeline_utils/icsGroupDeploy.sh
