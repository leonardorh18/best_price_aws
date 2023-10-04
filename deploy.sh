#!/bin/bash

# Nome do arquivo de modelo YAML
template_file="stack.yaml"

aws_access_key_id=$(aws configure get aws_access_key_id)
aws_secret_access_key=$(aws configure get aws_secret_access_key)
aws_region=$(aws configure get region)

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
  --capabilities "CAPABILITY_NAMED_IAM"

# Imprima a saída da pilha CloudFormation
aws cloudformation describe-stacks --stack-name $stack_name --query 'Stacks[0].Outputs'

