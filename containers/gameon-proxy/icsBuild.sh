#!/bin/bash
# The following colors have been defined to help with presentation of logs: green, red, label_color, no_color.  
log_and_echo "$LABEL" "Starting build script"

# The IBM Container Service CLI (ice), Git client (git), IDS Inventory CLI (ids-inv) and Python 2.7.3 (python) have been installed.
# Based on the organization and space selected in the Job credentials are in place for both IBM Container Service and IBM Bluemix 
#####################
# Run unit tests    #
#####################
log_and_echo "$LABEL" "No unit tests cases have been checked in"

######################################
# Build Container via Dockerfile     #
######################################

# REGISTRY_URL=${CCS_REGISTRY_HOST}/${NAMESPACE}
# FULL_REPOSITORY_NAME=${REGISTRY_URL}/${IMAGE_NAME}:${APPLICATION_VERSION}
# If you wish to receive slack notifications, set SLACK_WEBHOOK_PATH as a property on the stage.

if [ -f Dockerfile ]; then 
    log_and_echo "$LABEL" "Building ${FULL_REPOSITORY_NAME}"
    ${EXT_DIR}/utilities/sendMessage.sh -l info -m "New container build requested for ${FULL_REPOSITORY_NAME}"
    # build image
    BUILD_COMMAND=""
    if [ "${USE_CACHED_LAYERS}" == "true" ]; then 
        BUILD_COMMAND="build --pull --tag ${FULL_REPOSITORY_NAME} ${WORKSPACE}"
        ice_retry ${BUILD_COMMAND}
        RESULT=$?
    else 
        BUILD_COMMAND="build --no-cache --tag ${FULL_REPOSITORY_NAME} ${WORKSPACE}"
        ice_retry ${BUILD_COMMAND}
        RESULT=$?
    fi 

    if [ $RESULT -ne 0 ]; then
        log_and_echo "$ERROR" "Error building image"
        ice info 
        ice images
        ${EXT_DIR}/print_help.sh
        ${EXT_DIR}/utilities/sendMessage.sh -l bad -m "Container build of ${FULL_REPOSITORY_NAME} failed. $(get_error_info)"
        exit 1
    else
        log_and_echo "$SUCCESSFUL" "Container build of ${FULL_REPOSITORY_NAME} was successful"
        ${EXT_DIR}/utilities/sendMessage.sh -l good -m "Container build of ${FULL_REPOSITORY_NAME} was successful"
    fi  
else 
    log_and_echo "$ERROR" "Dockerfile not found in project"
    ${EXT_DIR}/utilities/sendMessage.sh -l bad -m "Failed to get Dockerfile. $(get_error_info)"
    exit 1
fi  

######################################################################################
# Copy any artifacts that will be needed for deployment and testing to $WORKSPACE    #
######################################################################################
echo "IMAGE_NAME=${FULL_REPOSITORY_NAME}" >> $ARCHIVE_DIR/build.properties
cp icsDeploy.sh $ARCHIVE_DIR

