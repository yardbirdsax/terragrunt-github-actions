#!/bin/bash

function stripColors {
  echo "${1}" | sed 's/\x1b\[[0-9;]*m//g'
}

function hasPrefix {
  case ${2} in
    "${1}"*)
      true
      ;;
    *)
      false
      ;;
  esac
}

function parseInputs {
  # Required inputs
  if [ "${INPUT_TF_ACTIONS_VERSION}" != "" ]; then
    tfVersion=${INPUT_TF_ACTIONS_VERSION}
  else
    echo "Input terraform_version cannot be empty"
    exit 1
  fi

  if [ "${INPUT_TG_ACTIONS_VERSION}" != "" ]; then
    tgVersion=${INPUT_TG_ACTIONS_VERSION}
  else
    echo "Input terragrunt_version cannot be empty"
    exit 1
  fi

  if [ "${INPUT_TF_ACTIONS_SUBCOMMAND}" != "" ]; then
    tfSubcommand=${INPUT_TF_ACTIONS_SUBCOMMAND}
  else
    echo "Input terraform_subcommand cannot be empty"
    exit 1
  fi

  # Optional inputs
  tfWorkingDir="."
  if [[ -n "${INPUT_TF_ACTIONS_WORKING_DIR}" ]]; then
    tfWorkingDir=${INPUT_TF_ACTIONS_WORKING_DIR}
  fi

  tfBinary="terragrunt"
  if [[ -n "${INPUT_TF_ACTIONS_BINARY}" ]]; then
    tfBinary=${INPUT_TF_ACTIONS_BINARY}
  fi

  tfComment=0
  if [ "${INPUT_TF_ACTIONS_COMMENT}" == "1" ] || [ "${INPUT_TF_ACTIONS_COMMENT}" == "true" ]; then
    tfComment=1
  fi

  tfCLICredentialsHostname=""
  if [ "${INPUT_TF_ACTIONS_CLI_CREDENTIALS_HOSTNAME}" != "" ]; then
    tfCLICredentialsHostname=${INPUT_TF_ACTIONS_CLI_CREDENTIALS_HOSTNAME}
  fi

  tfCLICredentialsToken=""
  if [ "${INPUT_TF_ACTIONS_CLI_CREDENTIALS_TOKEN}" != "" ]; then
    tfCLICredentialsToken=${INPUT_TF_ACTIONS_CLI_CREDENTIALS_TOKEN}
  fi

  tfFmtWrite=0
  if [ "${INPUT_TF_ACTIONS_FMT_WRITE}" == "1" ] || [ "${INPUT_TF_ACTIONS_FMT_WRITE}" == "true" ]; then
    tfFmtWrite=1
  fi

  tfWorkspace="default"
  if [ -n "${TF_WORKSPACE}" ]; then
    tfWorkspace="${TF_WORKSPACE}"
  fi

  tfPreCommands="${INPUT_TF_ACTIONS_PRE_COMMANDS}"

  downloadRetryAttempts="${INPUT_DOWNLOAD_RETRY_ATTEMPTS}"
  downloadRetryMaxTime="${INPUT_DOWNLOAD_MAX_TIME}"
}

function configureCLICredentials {
  if [[ ! -f "${HOME}/.terraformrc" ]] && [[ "${tfCLICredentialsToken}" != "" ]]; then
    cat > ${HOME}/.terraformrc << EOF
credentials "${tfCLICredentialsHostname}" {
  token = "${tfCLICredentialsToken}"
}
EOF
  fi
}

function installTerraform {
  if [[ "${tfVersion}" == "latest" ]]; then
    echo "Checking the latest version of Terraform"
    tfVersion=$(curl --retry-max-time ${downloadRetryMaxTime} --retry ${downloadRetryAttempts} --retry-connrefused -sL https://releases.hashicorp.com/terraform/index.json | jq -r '.versions[].version' | grep -v '[-].*' | sort -rV | head -n 1)

    if [[ -z "${tfVersion}" ]]; then
      echo "Failed to fetch the latest version"
      exit 1
    fi
  fi

  url="https://releases.hashicorp.com/terraform/${tfVersion}/terraform_${tfVersion}_linux_amd64.zip"

  echo "Downloading Terraform v${tfVersion}"
  curl --retry-max-time ${downloadRetryMaxTime} --retry ${downloadRetryAttempts} --retry-all-errors -s -S -L -o /tmp/terraform_${tfVersion} ${url}
  if [ "${?}" -ne 0 ]; then
    echo "Failed to download Terraform v${tfVersion}"
    exit 1
  fi
  echo "Successfully downloaded Terraform v${tfVersion}"

  echo "Unzipping Terraform v${tfVersion}"
  unzip -d /usr/local/bin /tmp/terraform_${tfVersion} &> /dev/null
  if [ "${?}" -ne 0 ]; then
    echo "Failed to unzip Terraform v${tfVersion}"
    exit 1
  fi
  echo "Successfully unzipped Terraform v${tfVersion}"
}

function installTerragrunt {
  if [[ "${tgVersion}" == "latest" ]]; then
    echo "Checking the latest version of Terragrunt"
    latestURL=$(curl --retry-max-time ${downloadRetryMaxTime} --retry ${downloadRetryAttempts} --retry-connrefused -Ls -o /dev/null -w %{url_effective} https://github.com/gruntwork-io/terragrunt/releases/latest)
    tgVersion=${latestURL##*/}

    if [[ -z "${tgVersion}" ]]; then
      echo "Failed to fetch the latest version"
      exit 1
    fi
  fi

  url="https://github.com/gruntwork-io/terragrunt/releases/download/${tgVersion}/terragrunt_linux_amd64"

  echo "Downloading Terragrunt ${tgVersion}"
  curl --retry-max-time ${downloadRetryMaxTime} --retry ${downloadRetryAttempts} --retry-all-errors -s -S -L -o /tmp/terragrunt ${url}
  if [ "${?}" -ne 0 ]; then
    echo "Failed to download Terragrunt ${tgVersion}"
    exit 1
  fi
  echo "Successfully downloaded Terragrunt ${tgVersion}"

  echo "Moving Terragrunt ${tgVersion} to PATH"
  chmod +x /tmp/terragrunt
  mv /tmp/terragrunt /usr/local/bin/terragrunt
  if [ "${?}" -ne 0 ]; then
    echo "Failed to move Terragrunt ${tgVersion}"
    exit 1
  fi
  echo "Successfully moved Terragrunt ${tgVersion}"
}

function executePreCommands {
  if [ -n "${tfPreCommands}" ]; then
    echo "Executing pre commands"

    local -r preCommandsScript=/tmp/preCommands.sh
    export ENV_VAR_FILE=/tmp/envVars.sh
    printf "%s" "${tfPreCommands}" > ${preCommandsScript}
    chmod +x ${preCommandsScript}
    chmod +x ${ENV_VAR_FILE}

    local -r stopToken=$(uuidgen)
    echo "::stop-commands::${stopToken}"
    bash -eo pipefail ${preCommandsScript}
    echo "::start-commands::${stopToken}"
    if [ -f "${ENV_VAR_FILE}" ]; then
      echo "loading environment variables from pre commands"
      export $(cat ${ENV_VAR_FILE} | xargs -0)
    fi
  fi
}

function findTerraformDir {
  local dot_terraform_dir=$(find ".terragrunt-cache" -type d -name ".terraform")
  local terraform_dir=$(dirname $dot_terraform_dir)
  echo "$terraform_dir"
}

function main {
  # Source the other files to gain access to their functions
  scriptDir=$(dirname ${0})
  source ${scriptDir}/terragrunt_fmt.sh
  source ${scriptDir}/terragrunt_init.sh
  source ${scriptDir}/terragrunt_validate.sh
  source ${scriptDir}/terragrunt_plan.sh
  source ${scriptDir}/terragrunt_apply.sh
  source ${scriptDir}/terragrunt_output.sh
  source ${scriptDir}/terragrunt_import.sh
  source ${scriptDir}/terragrunt_taint.sh
  source ${scriptDir}/terragrunt_destroy.sh
  source ${scriptDir}/terragrunt_show.sh
  source ${scriptDir}/terragrunt_json_file.sh

  parseInputs
  configureCLICredentials
  installTerraform
  executePreCommands
  cd ${GITHUB_WORKSPACE}/${tfWorkingDir}

  mainExitCode=0

  case "${tfSubcommand}" in
    fmt)
      installTerragrunt
      terragruntFmt ${*}
      ;;
    init)
      installTerragrunt
      terragruntInit ${*}
      ;;
    validate)
      installTerragrunt
      terragruntValidate ${*}
      ;;
    plan)
      installTerragrunt
      terragruntPlan ${*}
      ;;
    apply)
      installTerragrunt
      terragruntApply ${*}
      ;;
    output)
      installTerragrunt
      terragruntOutput ${*}
      ;;
    import)
      installTerragrunt
      terragruntImport ${*}
      ;;
    taint)
      installTerragrunt
      terragruntTaint ${*}
      ;;
    destroy)
      installTerragrunt
      terragruntDestroy ${*}
      ;;
    show)
      installTerragrunt
      terragruntShow ${*}
      ;;
    show_json)
      installTerragrunt
      terragruntJsonFile ${*}
      ;;
    *)
      echo "Error: Must provide a valid value for terragrunt_subcommand"
      mainExitCode=1
      ;;
  esac

  # Process the working dir if we have a non-errored exit code
  if [ ${mainExitCode} -ne 1 ]; then
    # Pass the directory used for processing terraform to the outputs
    terraformDir="$(findTerraformDir)"
    echo "tf_actions_terraform_dir=${terraformDir}" >> ${GITHUB_OUTPUT}
  fi

  # Exit with the exit code derived in a function call
  exit ${mainExitCode}
}

main "${*}"
