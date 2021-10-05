#!/bin/bash

# Initial values
SESSION_DURATION=3600

print_help() {
  echo '''Usage: source ./aws-set-session-key.sh --set --mfa-arn AWS_MFA_ARN --mfa-code 000000 [--duration 3600] [--profile AWS_CLI_PROFILE]
       source ./aws-set-session-key.sh --unset'''
}

set_session_key() {
  SESSION_CREDENTIAL=$(aws sts get-session-token --serial-number ${1} --token-code ${2} --duration-seconds ${3} $([[ -n ${4} ]] && echo "--profile ${4}"))
  [[ $? -gt 0 ]] && echo "Unable to fetch aws cli session credentials" && return 1
  export AWS_ACCESS_KEY_ID="$(echo ${SESSION_CREDENTIAL} | jq -r '.Credentials.AccessKeyId')"
  export AWS_SECRET_ACCESS_KEY="$(echo ${SESSION_CREDENTIAL} | jq -r '.Credentials.SecretAccessKey')"
  export AWS_SESSION_TOKEN=example-"$(echo ${SESSION_CREDENTIAL} | jq -r '.Credentials.SessionToken')"
  echo "AWS CLI Session credentials set successfuly"
}

unset_aws_session() {
  if [[ -z ${AWS_ACCESS_KEY_ID} ]]; then
    echo "AWS_ACCESS_KEY_ID is not set"
  else
    unset AWS_ACCESS_KEY_ID
    echo "AWS_ACCESS_KEY_ID is removed"
  fi

  if [[ -z ${AWS_SECRET_ACCESS_KEY} ]]; then
    echo "AWS_SECRET_ACCESS_KEY is not set"
  else
    unset AWS_SECRET_ACCESS_KEY
    echo "AWS_SECRET_ACCESS_KEY is removed"
  fi

  if [[ -z ${AWS_SESSION_TOKEN} ]]; then
    echo "AWS_SESSION_TOKEN is not set"
  else
    unset AWS_SESSION_TOKEN
    echo "AWS_SESSION_TOKEN is removed"
  fi
}

if [[ $# -eq 0 ]]; then
  echo "Invalid usage. Required parameters missing"
  print_help
  return 1
fi

while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -h|--help)
      print_help
      export AWS_SESSION_TOKEN=t
      return 0
      ;;
    --unset)
      unset_aws_session
      return 0
      ;;
    --set)
      IS_SET_OPERATION=y
      shift
      ;;
    --mfa-arn)
      [[ -z ${2} || ${2} =~ "--" ]] && echo "MFA ARN value cannot be empty" && return 1
      MFA_ARN="${2}"
      shift 2
      ;;
    --mfa-code)
      [[ -z ${2} || ${2} =~ "--" ]] && echo "MFA Code value cannot be empty" && return 1
      MFA_CODE="${2}"
      shift 2
      ;;
    --duration)
      [[ -z ${2} || ${2} =~ "--" ]] && echo "Session duration value cannot be empty" && return 1
      SESSION_DURATION="${2}"
      shift 2
      ;;
    --profile)
      [[ -z ${2} || "${2}" =~ "--" ]] && echo "AWS CLI profile value cannot be empty" && return 1
      AWS_CLI_PROFILE=${2}
      shift 2
      ;;
    *)    # unknown option
      echo "Unsupported parameter: ${2}"
      return 1
      ;;
  esac
done

set_session_key ${MFA_ARN} ${MFA_CODE} ${SESSION_DURATION} ${AWS_CLI_PROFILE:-""}

# set -- "${POSITIONAL[@]}" # restore positional parameters
