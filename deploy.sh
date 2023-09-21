#!/bin/bash

# Nome do arquivo de modelo YAML
template_file="stack.yaml"

# Nome da pilha do CloudFormation
stack_name="MelhorPreco"

# Nome do bucket S3 passado como parâmetro para o template
s3_bucket_name="melhor-preco-10-raw"

if [ -z "$s3_bucket_name" ]; then
  echo "Erro: O nome do bucket S3 deve ser fornecido como argumento."
  exit 1
fi
# Crie o bucket S3 para o código da Lambda
lambda_code_bucket="melhor-preco-lambda-code"

# Nome do arquivo ZIP que contém o código da Lambda
lambda_code_package="src.zip"

aws s3 mb s3://$lambda_code_bucket

# Empacote o código da Lambda e faça o upload para o bucket S3
zip -r $lambda_code_package ./src
aws s3 cp $lambda_code_package s3://$lambda_code_bucket/$lambda_code_package

sam validate -t stack.yaml
# Crie ou atualize a pilha CloudFormation
aws cloudformation deploy  \
  --stack-name $stack_name \
  --template-file $template_file \
  --parameter-overrides \
    BucketName=${s3_bucket_name} \
    CodeBucketName=${lambda_code_bucket} \
    CodeFileName=s3://${lmbda_code_bucket}/${lambda_code_package} \
  --capabilities "CAPABILITY_NAMED_IAM"

# Imprima a saída da pilha CloudFormation
aws cloudformation describe-stacks --stack-name $stack_name --query 'Stacks[0].Outputs'
