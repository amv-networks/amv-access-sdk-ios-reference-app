#!/bin/sh

AMVKIT_DIR="amv-framework-ios"
AMVKIT_FRAMWORK="${AMVKIT_DIR}/AMVKit.framework"


# Check if the kit has been downloaded before
if [ ! -d "${AMVKIT_DIR}" ]; then
    sh "DownloadScript.sh"
else
    # If yes, pull the latest and BUILD again
    echo "Updating AMVKit..."

    cd "${AMVKIT_DIR}"
    git pull origin master

    echo "Building AMVKit..."
    sh "BuildScript.sh"
fi


# Happniess
echo "Update complete"

