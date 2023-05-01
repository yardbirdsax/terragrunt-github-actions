#!/bin/bash

function terragruntJsonFile {
  echo "show_json: info: outputting plan in json format to ${tfWorkingDir}/tf_plan.json"
  ${tfBinary} show -json ${*} > tf_plan.json
  showExitCode=${?}

  mainExitCode=${showExitCode}
}
