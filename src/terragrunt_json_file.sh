#!/bin/bash

function terragruntJsonFile {
  # Gather the output of `terragrunt plan`.
  echo "show_json: info: outputting plan in json format to ${tfWorkingDir}/tf_plan.json"
  ${tfBinary} show -json ${*} > ${tfWorkingDir}/tf_plan.json
  showExitCode=${?}

  exit ${showExitCode}
}
