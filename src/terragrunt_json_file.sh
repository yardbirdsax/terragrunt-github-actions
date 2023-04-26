#!/bin/bash

function terragruntJsonFile {
  echo "show_json: info: outputting plan in json format to ${tfWorkingDir}/tf_plan.json"
  ${tfBinary} show -json ${*} > tf_plan.json
  showExitCode=${?}

  # Pass the directory used for processing terraform to the outputs
  terraformDir=$(findTerraformDir)
  echo "tf_actions_terraform_dir=${terraformDir}" >> ${GITHUB_OUTPUT}

  exit ${showExitCode}
}
