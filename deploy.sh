#!/bin/bash

# Nome do arquivo de modelo YAML
template_file="stack.yaml"

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
  --capabilities "CAPABILITY_NAMED_IAM"

# Imprima a saída da pilha CloudFormation
aws cloudformation describe-stacks --stack-name $stack_name --query 'Stacks[0].Outputs'

