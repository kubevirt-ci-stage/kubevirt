#!/bin/bash
#
# This file is part of the KubeVirt project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Copyright 2017 Red Hat, Inc.
#

set -e

source hack/common.sh
source hack/config.sh

manifest_docker_prefix=${manifest_docker_prefix-${docker_prefix}}

args=$(cd ${KUBEVIRT_DIR}/manifests && find * -type f -name "*.yaml.in")

rm -rf ${MANIFESTS_OUT_DIR}

for arg in $args; do
    final_out_dir=$(dirname ${MANIFESTS_OUT_DIR}/${arg})
    mkdir -p ${final_out_dir}
    manifest=$(basename -s .in ${arg})
    outfile=${final_out_dir}/${manifest}
    sed -e "s#{{ docker_tag }}#${docker_tag}#g" \
        -e "s#{{ docker_prefix }}#${manifest_docker_prefix}#g" \
        -e "s#{{ namespace }}#${namespace}#g" \
        ${KUBEVIRT_DIR}/manifests/$arg >${outfile}

    set +e
    grep -q '^.*APPEND_AUTOGENERATED_VM_CRD$' $outfile
    append_vm_crd=$?
    grep -q '^.*APPEND_AUTOGENERATED_VMRS_CRD$' $outfile
    append_vmrs_crd=$?
    grep -q '^.*APPEND_AUTOGENERATED_VMPRESET_CRD$' $outfile
    append_vmpreset_crd=$?
    grep -q '^.*APPEND_AUTOGENERATED_OVM_CRD$' $outfile
    append_ovm_crd=$?
    set -e

    if [ "$append_vm_crd" -eq 0 ]; then
        cat ${KUBEVIRT_DIR}/manifests/generated/vm-resource.yaml >>$outfile
    fi
    if [ "$append_vmrs_crd" -eq 0 ]; then
        cat ${KUBEVIRT_DIR}/manifests/generated/vmrs-resource.yaml >>$outfile
    fi
    if [ "$append_vmpreset_crd" -eq 0 ]; then
        cat ${KUBEVIRT_DIR}/manifests/generated/vmpreset-resource.yaml >>$outfile
    fi
    if [ "$append_ovm_crd" -eq 0 ]; then
        cat ${KUBEVIRT_DIR}/manifests/generated/ovm-resource.yaml >>$outfile
    fi
done
