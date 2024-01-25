#!/bin/bash

#  Copyright 2018 Pusher Ltd. and Wave Contributors
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

# sig-mirror tool
MAINTAINER_EMAIL="midu@redhat.com"

# Variables read from the config.yaml file managed by the user
read_yaml() {
  local yaml_file="$1"

  # Check if the YAML file exists
  if [ ! -f "$yaml_file" ]; then
    echo "Error: YAML file '$yaml_file' not found."
    exit 1
  fi

  # Read variables from YAML file
  export ocp_release_version=$(yq e '.ocp_release_version' "$yaml_file")
  export redhat_operator_index_version=$(yq e '.redhat_operator_index_version' "$yaml_file")
  export release_number=$(yq e '.release_number' "$yaml_file")
  export registry_fqdn=$(yq e '.registry_fqdn' "$yaml_file")
  export registry_port=$(yq e '.registry_port' "$yaml_file")
  export operator_list=($(yq e '.operator_list | join(" ")' "$yaml_file"))
  export registry_port=$(yq e '.signer_email' "$yaml_file")
}

# Making sure that we have the dependencies alligned with the release
dependencies_checker() {
  local dependencies_directory="${working_directory}/dependencies"

  # Check if the dependencies directory exists
  if [ ! -d "$dependencies_directory" ]; then
      # Create the working directory if it doesn't exist
      mkdir -p "$dependencies_directory"
  fi

  # Public File URLs
  yq_binary_url="https://github.com/mikefarah/yq/releases/download/v4.40.5/yq_linux_arm64.tar.gz"

  # Check if yq binary exists, download and extract if not
  if [ ! -f "${dependencies_directory}/yq" ]; then
    # Download and extract oc-mirror
    curl -sSL "${yq_binary_url}" -o "${dependencies_directory}/yq_linux_arm64.tar.gz"
    # Untar the downloaded file in the specified directory
    tar -xzvf "${dependencies_directory}/yq_linux_arm64.tar.gz" -C "${dependencies_directory}"
    # Make sure that the oc its executable
    chmod +x "${dependencies_directory}/yq_linux_arm64"
    # Changing the naming
    mv "${dependencies_directory}/yq_linux_arm64" "${dependencies_directory}/yq"
  else
    echo "${dependencies_directory}/yq exists."
  fi
  export PATH="$PATH:$dependencies_directory"
  #echo $PATH #only for debugging
}

# Making sure that we have the dependencies alligned with the release
ocp_dependencies_checker() {
  local dependencies_directory="${working_directory}/dependencies"

  # Check if the dependencies directory exists
  if [ ! -d "$dependencies_directory" ]; then
      # Create the working directory if it doesn't exist
      mkdir -p "$dependencies_directory"
  fi

  # Public File URLs
  oc_mirror_url="$redhat_binary_preparation_url/$ocp_release_version/oc-mirror.tar.gz"
  openshift_client_url="$redhat_binary_preparation_url/$ocp_release_version/openshift-client-linux-$ocp_release_version.tar.gz"

  # Check if oc-mirror binary exists, download and extract if not
  if [ ! -f "${dependencies_directory}/oc-mirror" ]; then
    # Download and extract oc-mirror
    curl -sSL "${oc_mirror_url}" -o "${dependencies_directory}/oc-mirror.tar.gz"
    # Untar the downloaded file in the specified directory
    tar -xzvf "${dependencies_directory}/oc-mirror.tar.gz" -C "${dependencies_directory}"
    # Make sure that the oc-mirror its executable
    chmod +x "${dependencies_directory}/oc-mirror"
  else
    echo "${dependencies_directory}/oc-mirror exists."
  fi

  # Check if oc binary exists, download and extract if not
  if [ ! -f "${dependencies_directory}/oc" ]; then
    # Download and extract oc-mirror
    curl -sSL "${openshift_client_url}" -o "${dependencies_directory}/openshift-client-linux-$ocp_release_version.tar.gz"
    # Untar the downloaded file in the specified directory
    tar -xzvf "${dependencies_directory}/openshift-client-linux-$ocp_release_version.tar.gz" -C "${dependencies_directory}"
    # Make sure that the oc its executable
    chmod +x "${dependencies_directory}/oc"
  else
    echo "${dependencies_directory}/oc exists."
  fi
  export PATH="$PATH:$dependencies_directory"
  #echo $PATH #only for debugging
}


# Creating the working directory of the signature
working_dir_generator() {
  # Check if the working directory exists
  if [ ! -d "$working_directory" ]; then
      # Create the working directory if it doesn't exist
      mkdir -p "$working_directory"
  fi
}

get_latest_version() {
  local operator_names=("$@")

  # Generate YAML configuration
  yaml_config="---
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  platform:
    channels:
    - name: "${stable_version}"
      minVersion: "${ocp_release_version}"
      maxVersion: "${ocp_release_version}"
      type: ocp
    graph: true
  operators:
    - catalog: \"${redhat_operator_index_catalog}:${redhat_operator_index_version}\"
      targetName: "redhat-operator-index"
      targetTag: "${target_tag}"
      packages:"

  for operator_name in "${operator_names[@]}"; do
    # Extract default channel
    default_channel=$(oc-mirror list operators --catalog "${redhat_operator_index_catalog}:${redhat_operator_index_version}" --package "$operator_name" | awk 'NR==3 {print $NF}')
    # Extract versions (assuming they are the lines after "VERSIONS" header)
    versions=$(oc-mirror list operators --catalog "${redhat_operator_index_catalog}:${redhat_operator_index_version}" --package "$operator_name" --channel=${default_channel} | awk 'NR>1')

    # Remove alphanumeric characters and determine the highest version
    highest_version=$(echo "$versions" | tr -d '[:alpha:]' | sort -Vr | head -n 1)

    # Add back alphanumeric characters to the highest version
    highest_version_with_chars=$(echo "$versions" | grep "$highest_version")

    echo "=============================================="
    echo "Default channel: ${default_channel}"
    echo "=============================================="
    echo "Highest Version for ${operator_name}: ${highest_version_with_chars}"

    # Generate YAML configuration
    yaml_config+="
        - {'name': '$operator_name', 'channels': [{'name': '${default_channel}', 'minVersion': '${highest_version_with_chars}', 'maxVersion': '${highest_version_with_chars}'}]}"
    # echo "$yaml_config" #only for debugging
  done  # Corrected placement of 'done' here

    # Save the YAML configuration to a file
    output_file="imageset-config.yaml"
    echo "$yaml_config" > "${working_directory}/${output_file}"

    echo "=============================================="
    echo "Generated YAML file for ${operator_name}: ${output_file}"
    echo "=============================================="
}

# We will have to mirror the content to a Semy-Offline Cache-Registry
mirroring_to_cache_registry () {
  # Run netcat command and capture the output
  local netcat_output=$(netcat -z -v "${registry_fqdn}" "${registry_port}" 2>&1)
  echo $netcat_output
  # Check if the output includes "succeeded"
  if echo "$netcat_output" | grep -q "succeeded"; then
    echo "Connection succeeded to the Cache-Registry. Proceeding with mirroring."
    # Run oc-mirror command mirror the packages to the Cache-Registry and capture the output
    local mirroring_to_cache_registry_var=$(oc-mirror --config "${working_directory}/imageset-config.yaml" "docker://${registry_fqdn}:${registry_port}/${target_tag,,}" --dest-skip-tls=true)
    # echo ${mirroring_to_cache_registry_var}
    # Check the return code
    if [ $? -eq 0 ]; then
      echo "imageset-config.yaml mirroring is complete."
      local output_mirroring_file="mirroring-oc-mirror.log"
      echo "$mirroring_to_cache_registry_var" > "${working_directory}/${output_mirroring_file}"
    else
      echo "Error: imageset-config.yaml mirroring failed. Make sure to check the .oc-mirror.log file made available."
    fi
  else
    echo "Error: Connection to the Cache-Registry failed. Exiting with error code."
    exit 1
  fi
}

# Sign all the container base images mirrored to the Cache-Registry
signing_images () {
  local ImageListFile=$( cat sig-work-dir/mirroring-oc-mirror.log | grep -oP 'oc-mirror-workspace/results-\d+/mapping.txt' | head -n 1)
  local InternalReleaseDir="${working_directory}/${target_tag,,}"

  # Check if the dependencies directory exists
  if [ ! -d "$InternalReleaseDir" ]; then
      # Create the working directory if it doesn't exist
      mkdir -p "$InternalReleaseDir"
  fi
  # Read the list of images
  while IFS= read -r IMAGE; do
    # Extract image details
    SourceImage=$(echo "$IMAGE" | cut -d'/' -f2-)
    echo $SourceImage >> "${working_directory}/bundle-mirror.log"
    DestImage="docker://${REGISTRY}/signed/${SourceImage}"
    
    IMAGE_NAME_DIGEST=$(echo "$IMAGE" | awk -F'/' '{print $NF}')
    echo "---------------------------------------------------------------"
    echo "Signing the operator image and push to Offline-Registry cache:"
    # Perform skopeo copy with signature
    skopeo copy --sign-by "${SIGNER_EMAIL}" "docker://${IMAGE}" "${DestImage}" --dest-tls-verify=false --src-tls-verify=false

    echo "---------------------------------------------------------------"
    echo "Preparing the localhost directory clone:"    
    # Perform skopeo copy to local directory to prepare the bundle.tar.gz
#    skopeo copy --format oci "${DestImage}" "dir:${InternalReleaseDir}/${IMAGE_NAME_DIGEST}"
    echo "---------------------------------------------------------------"
    # Print a newline for better readability
    echo
  done < <(cat "${ImageListFile}" | awk -F= '{print $2}')
}

# Prepare the Internal Signed Build
# _main_
# Variable that defines the signature-working-directory
working_directory="$(pwd)/sig-work-dir"

dependencies_checker
read_yaml "config.yaml"

# Defining the static Variables
original_string="${release_number}-ocp-${ocp_release_version}-someone"
# Variables that will be encoded
redhat_operator_index_catalog='registry.redhat.io/redhat/redhat-operator-index'
redhat_binary_preparation_url='https://mirror.openshift.com/pub/openshift-v4/clients/ocp'
# Get the current date in the format YY.MM.DD
date_string=$(date +"%y.%m.%d")
# Append the date string
target_tag="${original_string}.${date_string}"
# Extract major and minor versions
major_version=$(echo "$ocp_release_version" | cut -d. -f1)
minor_version=$(echo "$ocp_release_version" | cut -d. -f2)
# Construct 'stable' version
stable_version="stable-$major_version.$minor_version"
################################################################################

ocp_dependencies_checker
# Example usage with a list of operators
# operator_list=("advanced-cluster-management" "multicluster-engine" "topology-aware-lifecycle-manager" "openshift-gitops-operator" "cincinnati-operator" "odf-operator" "ptp-operator" "lvms-operator" "mcg-operator" "ocs-operator" "odf-csi-addons-operator" "sriov-network-operator" "cluster-logging" "local-storage-operator")
working_dir_generator
get_latest_version "${operator_list[@]}"
mirroring_to_cache_registry
signing_images