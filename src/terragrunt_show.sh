#!/bin/bash

function terragruntShow {
  # Gather the output of `terragrunt plan`.
  echo "show: info: planning Terragrunt configuration in ${tfWorkingDir}"
  showOutput=$(${tfBinary} show ${*})
  showExitCode=${?}
  planHasChanges=false
  planCommentStatus="Failed"

  # Exit code of 0 indicates success with no changes. Print the output and exit.
  if [ ${showExitCode} -eq 0 ]; then
    echo "plan: info: successfully showing Terragrunt configuration in ${tfWorkingDir}"
    echo "${showOutput}"
    echo
    echo ::set-output name=tf_actions_plan_has_changes::${planHasChanges}

  else
    echo "show: error: failed to show Terragrunt configuration in ${tfWorkingDir}"
    echo "${showOutput}"
    echo
  fi

  exit ${showExitCode}
}
