#!/bin/bash

#--------------------------------------------------------------------------------------------------------------------
#                       $$\                                                          $$\     
#                       $$ |                                                         $$ |    
#   $$$$$$$\  $$\   $$\ $$$$$$$\   $$$$$$\  $$\   $$\  $$$$$$\   $$$$$$\   $$$$$$\ $$$$$$\   
#   $$  __$$\ $$ |  $$ |$$  __$$\ $$  __$$\ \$$\ $$  |$$  __$$\ $$  __$$\ $$  __$$\\_$$  _|  
#   $$ |  $$ |$$ |  $$ |$$ |  $$ |$$$$$$$$ | \$$$$  / $$ /  $$ |$$$$$$$$ |$$ |  \__| $$ |    
#   $$ |  $$ |$$ |  $$ |$$ |  $$ |$$   ____| $$  $$<  $$ |  $$ |$$   ____|$$ |       $$ |$$\ 
#   $$ |  $$ |\$$$$$$  |$$$$$$$  |\$$$$$$$\ $$  /\$$\ $$$$$$$  |\$$$$$$$\ $$ |       \$$$$  |
#   \__|  \__| \______/ \_______/  \_______|\__/  \__|$$  ____/  \_______|\__|        \____/ 
#                                                     $$ |                                   
#                                                     $$ |                                   
#                                                     \__|                                   
# Parameters:
#   $1; BASE PROFILE NAME, FROM WHICH THE CREDENTIALS ARE TAKEN
#   $2; MFA PROFILE NAME TO SET THE STS TOKEN (THE NAME YOU WANT)
#--------------------------------------------------------------------------------------------------------------------

#Colours
greenColour="\033[0;32m"
redColour="\033[0;31m"
blueColour="\033[0;34m"
yellowColour="\033[1;33m"
endColour="\033[0m"

# Functions to log messages
function LOG_OK {
    echo -e "${blueColour}INFO [$(date +"%Y-%m-%d %H:%M:%S")]: ${1}${endColour}"
}

function LOG_ERROR {
    echo -e "${redColour}INFO [$(date +"%Y-%m-%d %H:%M:%S")]: ${1}${endColour}"
}

function Exit_Error {
    exit 1
}

if [ $# -ne 2 ]
then
    LOG_ERROR "Number of invalid arguments. Exiting.... "
    Exit_Error
fi

# Get profile names from arguments
BASE_PROFILE_NAME="${1}"
MFA_PROFILE_NAME="${2}"


# Set default region
DEFAULT_REGION="us-east-1"

# Set default Output
DEFAULT_OUTPUT="json"

# ARN Example: arn:aws:iam::123456789123:mfa/iamuser
MFA_SERIAL="arn:aws:iam::123456789012:mfa/iam-user"

# Generate Security token Flag
GENERATE_ST="true"

# Checking if there is a token, and if it is still valid
MFA_PROFILE_EXISTS=`more ~/.aws/credentials | grep "${MFA_PROFILE_NAME}" | wc -l`
if [ "${MFA_PROFILE_EXISTS}" -eq 1 ]; then
    EXPIRATION_TIME=$(aws configure get expiration --profile "${MFA_PROFILE_NAME}")
    NOW=$(date -u +"%Y-%m-%dT%H:%M:%S"+00:00)
    if [[ "${EXPIRATION_TIME}" > "${NOW}" ]]; then
        LOG_OK "---------------------------------------------------------------------------------------"
        LOG_OK "The session Token is still valid. New Security Token is not required."
        LOG_OK "---------------------------------------------------------------------------------------"
        GENERATE_ST="false"
    fi
fi

# Generating STS token
if [ "${GENERATE_ST}" = "true" ]; then
    read -p "Token code for MFA Device (${MFA_SERIAL}): " TOKEN_CODE
    LOG_OK "---------------------------------------------------------------------------------------"
    LOG_OK "Generating new IAM STS Token ..."
    LOG_OK "---------------------------------------------------------------------------------------"
    read -r AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN EXPIRATION < <(aws sts get-session-token --profile "${BASE_PROFILE_NAME}" --output text --query 'Credentials.*' --serial-number "${MFA_SERIAL}" --token-code "${TOKEN_CODE}")
    if [ $? -ne 0 ]; then
        LOG_ERROR "---------------------------------------------------------------------------------------"
        LOG_ERROR "An error ocurred. AWS credentials file not updated"
        LOG_ERROR "---------------------------------------------------------------------------------------"
    else
        aws configure set aws_access_key_id "${AWS_ACCESS_KEY_ID}" --profile "${MFA_PROFILE_NAME}"
        aws configure set aws_secret_access_key "${AWS_SECRET_ACCESS_KEY}" --profile "${MFA_PROFILE_NAME}"
        aws configure set aws_session_token "${AWS_SESSION_TOKEN}" --profile "${MFA_PROFILE_NAME}"
        aws configure set expiration "${EXPIRATION}" --profile "${MFA_PROFILE_NAME}"
        aws configure set region "${DEFAULT_REGION}" --profile "${MFA_PROFILE_NAME}"
        aws configure set output "${DEFAULT_OUTPUT}" --profile "${MFA_PROFILE_NAME}"
        LOG_OK "---------------------------------------------------------------------------------------"
        LOG_OK "STS Session Token generated and updated in AWS credentials file successfully"
        LOG_OK "---------------------------------------------------------------------------------------"
    fi
fi