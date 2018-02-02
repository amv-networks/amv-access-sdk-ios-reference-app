#!/bin/sh

AMVKIT_DIR="amv-access-sdk-ios"
AMVKIT_FRAMEWORK="${AMVKIT_DIR}/AMVKit.framework"


# Download the AMVKit repo
if [ ! -d "${AMVKIT_DIR}" ]; then
    echo "Downloading AMVKit repo..."
    git clone https://github.com/amv-networks/amv-access-sdk-ios.git
fi


# Build the AMVKit
if [ ! -d "${AMVKIT_FRAMEWORK}" ]; then
    echo "Building AMVKit..."

    cd "${AMVKIT_DIR}"
    sh "BuildScript.sh"
fi


echo "All frameworks present"

