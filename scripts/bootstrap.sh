#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# scripts/bootstrap.sh
# Sobe toda a infraestrutura AWS com UM comando.
#
# Pré-requisitos:
#   - AWS CLI instalado e configurado (aws configure)
#   - Docker instalado
#   - Permissões: ECR, ECS, S3, CloudFormation, IAM, EC2
#
# Uso: bash scripts/bootstrap.sh
# ══════════════════════════════════════════════════════════════════

set -euo pipefail   # para em qualquer erro

# ── Cores para output ──────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERR]${NC} $1"; exit 1; }

# ── Configuração — edite aqui ──────────────────────────────────────
APP_NAME="${APP_NAME:-aws-test-app}"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"
STACK_NAME="${APP_NAME}"

# ── Verifica pré-requisitos ────────────────────────────────────────
info "Verificando pré-requisitos..."
command -v aws    >/dev/null 2>&1 || error "AWS CLI não encontrado. Instale: https://aws.amazon.com/cli/"
command -v docker >/dev/null 2>&1 || error "Docker não encontrado."

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
info "AWS Account: $ACCOUNT_ID | Região: $REGION"

ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

# ── 1. Deploy do CloudFormation ────────────────────────────────────
info "1/4 Criando infraestrutura via CloudFormation..."
aws cloudformation deploy \
  # --template-file infra/cloudformation.yml \
  --stack-name "$STACK_NAME" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides AppName="$APP_NAME" \
  --region "$REGION" \
  --no-fail-on-empty-changeset

info "Stack criada/atualizada com sucesso!"

# ── 2. Build da imagem Docker ──────────────────────────────────────
info "2/4 Buildando imagem Docker..."
IMAGE_TAG=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")
docker build -t "$ECR_URL/$APP_NAME:$IMAGE_TAG" -t "$ECR_URL/$APP_NAME:latest" .

# ── 3. Push para ECR ───────────────────────────────────────────────
info "3/4 Enviando imagem para ECR..."
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$ECR_URL"

docker push "$ECR_URL/$APP_NAME:$IMAGE_TAG"
docker push "$ECR_URL/$APP_NAME:latest"
info "Imagem enviada: $ECR_URL/$APP_NAME:$IMAGE_TAG"

# ── 4. Força novo deploy no ECS ────────────────────────────────────
info "4/4 Atualizando serviço ECS..."
CLUSTER=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='ECSClusterName'].OutputValue" \
  --output text)

SERVICE=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='ECSServiceName'].OutputValue" \
  --output text)

aws ecs update-service \
  --cluster "$CLUSTER" \
  --service "$SERVICE" \
  --force-new-deployment \
  --region "$REGION" > /dev/null

info "Aguardando serviço estabilizar (pode levar ~2 min)..."
aws ecs wait services-stable \
  --cluster "$CLUSTER" \
  --services "$SERVICE" \
  --region "$REGION"

# ── Resumo ─────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}══════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Deploy concluído!${NC}"
echo -e "${GREEN}══════════════════════════════════════${NC}"
echo ""
echo "  Cluster:  $CLUSTER"
echo "  Service:  $SERVICE"
echo "  Imagem:   $ECR_URL/$APP_NAME:$IMAGE_TAG"
echo ""
echo "  Para ver os logs:"
echo "  aws logs tail /ecs/$APP_NAME --follow"
echo ""
warning "DICA FREE TIER: monitore custos em https://console.aws.amazon.com/billing"
