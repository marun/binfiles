#!/bin/bash
set -euo pipefail

PROFILE="${PROFILE:-openshift-dev}"

METADATA_FILE="${METADATA_FILE:-${PWD}/metadata.json}"
echo "Using metadata file ${METADATA_FILE}"

REGION="$( jq -r '.aws.region' "${METADATA_FILE}" )"
echo "Using region ${REGION}"

INFRA_ID="$( jq -r '.infraID' "${METADATA_FILE}" )"
echo "INFRA_ID is ${INFRA_ID}"

EC2_CMD="aws --profile=${PROFILE} --region=${REGION} --output=json ec2"

INFRA_TAG="$( jq -r '.aws.identifier | map( keys[] | select(contains("'${INFRA_ID}'")) )[0]' "${METADATA_FILE}" )"
echo "INFRA_TAG is ${INFRA_TAG}"

SUBNET_JSON="$( ${EC2_CMD} describe-subnets\
 --filters "Name=tag-key,Values=${INFRA_TAG}"\
 | jq -r '.Subnets | map( select( any(.Tags[]; .Key=="Name" and ( .Value | contains("public") ) ) ) )[0]'\
 )"
VPC_ID="$( echo $SUBNET_JSON | jq -r '.VpcId' )"
echo "VPC_ID is ${VPC_ID}"

SUBNET_ID="$( echo $SUBNET_JSON | jq -r '.SubnetId' )"
echo "SUBNET_ID is ${SUBNET_ID}"

SG_NAME="${INFRA_ID}-ssh"
SG_ID="$( ${EC2_CMD} describe-security-groups\
 --filter="Name=vpc-id,Values=${VPC_ID}"\
 --filter="Name=group-name,Values=${SG_NAME}"\
 --query="SecurityGroups[].GroupId"\
 | jq -r '.[0]'\
 )"
if [[ "${SG_ID}" == "null" ]]; then
  SG_ID="$( ${EC2_CMD} create-security-group\
    --description=ssh\
    --group-name="${SG_NAME}"\
    --vpc-id="${VPC_ID}"\
    | jq -r '.GroupId'\
    )"
  ${EC2_CMD} authorize-security-group-ingress\
    --group-id="${SG_ID}"\
    --protocol=tcp\
    --port 22\
    --cidr 0.0.0.0/0
fi
echo "SG_ID is ${SG_ID}"

IMAGE_ID="$( ${EC2_CMD} describe-images\
 --owners aws-marketplace\
 --filters Name=product-code,Values=aw0evgkw8e5c1q413zgy5pjce\
 | jq -r '.Images | sort_by(.CreationDate) | reverse | first | .ImageId'\
 )"
echo "Using image ${IMAGE_ID}"

INSTANCE_ID="$( ${EC2_CMD} run-instances\
 --image-id="${IMAGE_ID}"\
 --count=1\
 --instance-type=t2.micro\
 --key-name=marun-dev\
 --security-group-ids="${SG_ID}"\
 --subnet-id="${SUBNET_ID}"\
 --associate-public-ip-address\
 --tag-specifications="ResourceType=instance,Tags=[{Key=Name,Value=${INFRA_ID}-bastion},{Key=${INFRA_TAG},Value=owned}]"\
 --query='Instances[0].InstanceId'\
 | sed -e 's/"//g'\
 )"
echo "Instance id is ${INSTANCE_ID}"

BASTION_IP=
while [[ -z "${BASTION_IP}" ]]; do
  BASTION_IP="$( ${EC2_CMD} describe-instances\
    --instance-ids="${INSTANCE_ID}"\
    --query='Reservations[0].Instances[0].PublicDnsName'\
    | sed -e 's/"//g'\
    || true\
    )"
done

echo "Bastion is starting..."
echo ""
echo "  ssh -i marun-dev.pem -A centos@${BASTION_IP}"
echo ""
