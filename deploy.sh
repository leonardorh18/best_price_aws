#!/bin/bash

# Nome do arquivo de modelo YAML
template_file="stack.yaml"

aws_access_key_id=$(aws configure get aws_access_key_id)
aws_secret_access_key=$(aws configure get aws_secret_access_key)
aws_region=$(aws configure get region)


default_vpc_id=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" | jq -r '.Vpcs[0].VpcId')
subnet=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${default_vpc_id}" "Name=default-for-az,Values=true" --query "Subnets[0].SubnetId" --output text)
security_group=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=${default_vpc_id}" "Name=group-name,Values=default" --query "SecurityGroups[0].GroupId" --output text)



# Nome da pilha do CloudFormation
stack_name="MelhorPreco"

# Nome do bucket S3 passado como parâmetro para o template
s3_bucket_name="melhor-preco-10-raw"

sam validate -t stack.yaml
# Crie ou atualize a pilha CloudFormation
aws cloudformation deploy  \
  --stack-name $stack_name \
  --template-file $template_file \
  --parameter-overrides \
    BucketName=${s3_bucket_name} \
    AwsAccessKey=${aws_access_key_id} \
    AwsSecretKey=${aws_secret_access_key} \
    AwsRegion=${aws_region} \
    SecurityGroup=${security_group} \
    Subnet=${subnet} \
  --capabilities "CAPABILITY_NAMED_IAM"

# Imprima a saída da pilha CloudFormation
aws cloudformation describe-stacks --stack-name $stack_name --query 'Stacks[0].Outputs'



