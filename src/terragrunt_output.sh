#!/bin/bash

function terragruntOutput {
  # Gather the output of `terragrunt output`.
  echo "output: info: gathering all the outputs for the Terragrunt configuration in ${tfWorkingDir}"
  outputOutput=$(${tfBinary} output -json ${*} 2>&1)
  outputExitCode=${?}

  # Exit code of 0 indicates success. Print the output and exit.
  if [ ${outputExitCode} -eq 0 ]; then
    echo "output: info: successfully gathered all the outputs for the Terragrunt configuration in ${tfWorkingDir}"
    echo "${outputOutput}"
    echo

    # https://github.community/t5/GitHub-Actions/set-output-Truncates-Multiline-Strings/m-p/38372/highlight/true#M3322
    outputOutput="${outputOutput//'%'/'%25'}"
    outputOutput="${outputOutput//$'\n'/'%0A'}"
    outputOutput="${outputOutput//$'\r'/'%0D'}"

    echo "tf_actions_output='${outputOutput}'" >> ${GITHUB_OUTPUT}
    exit ${outputExitCode}
  fi

  # Exit code of !0 indicates failure.
  echo "output: error: failed to gather all the outputs for the Terragrunt configuration in ${tfWorkingDir}"
  echo "${outputOutput}"
  echo
  exit ${outputExitCode}
}
