#!/bin/bash

function terragruntShow {
  # Gather the output of `terragrunt plan`.
  echo "show: info: planning Terragrunt configuration in ${tfWorkingDir}"
  showOutput=$(${tfBinary} show ${*})
  showExitCode=${?}

  # Pass the directory used for processing terraform to the outputs
  terraformDir=$(findTerraformDir)
  echo "tf_actions_terraform_dir='${terraformDir}'" >> ${GITHUB_OUTPUT}

  # Exit code of 0 indicates success with no changes. Print the output and exit.
  if [ ${showExitCode} -eq 0 ]; then
    echo "plan: info: successfully showing Terragrunt configuration in ${tfWorkingDir}"
    echo ${showOutput}
    echo "tf_actions_output=${showOutput}" >> $GITHUB_OUTPUT
    echo

  else
    echo "show: error: failed to show Terragrunt configuration in ${tfWorkingDir}"
    echo "${showOutput}"
    echo
  fi

  exit ${showExitCode}
}
