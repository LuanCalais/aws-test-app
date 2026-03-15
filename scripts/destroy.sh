#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# scripts/destroy.sh
# APAGA TUDO para garantir que não vai cobrar no Free Tier.
#
# Execute SEMPRE que terminar de estudar!
# ══════════════════════════════════════════════════════════════════

set -euo pipefail
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

APP_NAME="${APP_NAME:-aws-test-app}"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo -e "${RED}══════════════════════════════════════════${NC}"
echo -e "${RED}  ⚠️  ATENÇÃO: Isso vai APAGAR tudo!${NC}"
echo -e "${RED}══════════════════════════════════════════${NC}"
echo ""
echo "  Conta:  $ACCOUNT_ID"
echo "  Região: $REGION"
echo "  Stack:  $APP_NAME"
echo ""
read -p "Tem certeza? Digite 'sim' para confirmar: " CONFIRM
[[ "$CONFIRM" != "sim" ]] && { echo "Cancelado."; exit 0; }

# 1. Escala serviço para 0 (para de cobrar Fargate imediatamente)
echo -e "${YELLOW}Zerando tasks ECS...${NC}"
aws ecs update-service \
  --cluster "${APP_NAME}-cluster" \
  --service "${APP_NAME}-service" \
  --desired-count 0 \
  --region "$REGION" 2>/dev/null || true

# 2. Esvazia o bucket S3 (CloudFormation não apaga buckets com conteúdo)
echo -e "${YELLOW}Esvaziando bucket S3...${NC}"
BUCKET="${APP_NAME}-assets-${ACCOUNT_ID}"
aws s3 rm "s3://$BUCKET" --recursive --region "$REGION" 2>/dev/null || true

# 3. Remove todas as imagens do ECR
echo -e "${YELLOW}Removendo imagens ECR...${NC}"
IMAGE_IDS=$(aws ecr list-images \
  --repository-name "$APP_NAME" \
  --query 'imageIds[*]' \
  --output json \
  --region "$REGION" 2>/dev/null || echo "[]")

if [[ "$IMAGE_IDS" != "[]" && -n "$IMAGE_IDS" ]]; then
  aws ecr batch-delete-image \
    --repository-name "$APP_NAME" \
    --image-ids "$IMAGE_IDS" \
    --region "$REGION" 2>/dev/null || true
fi

# 4. Destrói a stack CloudFormation (apaga tudo mais)
echo -e "${YELLOW}Destruindo stack CloudFormation...${NC}"
aws cloudformation delete-stack \
  --stack-name "$APP_NAME" \
  --region "$REGION"

echo -e "${YELLOW}Aguardando deleção...${NC}"
aws cloudformation wait stack-delete-complete \
  --stack-name "$APP_NAME" \
  --region "$REGION"

echo ""
echo -e "${GREEN}✅ Tudo apagado! Você está seguro no Free Tier.${NC}"
echo ""
echo "Confira em: https://console.aws.amazon.com/billing/home#/bills"
