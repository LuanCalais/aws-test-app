# AWS Free Tier App 🚀

App Node.js completo para treino de arquitetura cloud moderna.

## Arquitetura

```
GitLab CI/CD
     │
     ▼
  [test] → [build] → [push ECR] → [deploy ECS] → [notify]
                          │
                    ┌─────▼──────┐
                    │  AWS Cloud  │
                    │             │
                    │  ECR 📦    │  ← repositório Docker
                    │  ECS ⚙️   │  ← executa container (Fargate)
                    │  S3  🪣   │  ← assets, logs
                    │  CW  📊   │  ← logs, métricas, alertas
                    └─────────────┘
```

## Estrutura do projeto

```
.
├── src/
│   ├── app.js          # Express API
│   └── app.test.js     # Testes Jest
├── public/
│   └── index.html      # Frontend
├── scripts/
│   ├── bootstrap.sh    # Sobe tudo com 1 comando
│   └── destroy.sh      # Apaga tudo (segurança Free Tier)
├── Dockerfile          # Multi-stage build
├── docker-compose.yml  # Desenvolvimento local
└── .gitlab-ci.yml      # Pipeline CI/CD
```

---

## 🚀 Guia passo a passo

### 1. Pré-requisitos

```bash
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip awscliv2.zip && sudo ./aws/install

# Configure com suas credenciais
aws configure
# AWS Access Key ID: (sua chave)
# AWS Secret Access Key: (seu segredo)
# Default region: us-east-1
# Default output format: json
```

### 2. Rodar localmente

```bash
# Com docker compose (recomendado)
docker compose up --build
# Acesse: http://localhost:3000

# Ou direto com node
npm install
npm run dev
```

### 3. Subir na AWS (primeira vez)

```bash
# Sobe tudo: CloudFormation + ECR + build + push + ECS
bash scripts/bootstrap.sh
```

### 4. Configurar GitLab CI/CD

Vá em **GitLab > Settings > CI/CD > Variables** e adicione:

| Variável | Valor | Protected |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | chave do IAM user | ✅ |
| `AWS_SECRET_ACCESS_KEY` | segredo do IAM | ✅ |
| `AWS_DEFAULT_REGION` | `us-east-1` | |
| `AWS_ACCOUNT_ID` | 12 dígitos da conta | |
| `ECR_REPO_NAME` | `aws-test-app` | |
| `ECS_CLUSTER` | `aws-test-app-cluster` | |
| `ECS_SERVICE` | `aws-test-app-service` | |
| `ECS_TASK_FAMILY` | `aws-test-app-task` | |

**IAM User de deploy** (crie em IAM > Users):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Action": ["ecr:*"], "Resource": "*" },
    { "Effect": "Allow", "Action": ["ecs:*"], "Resource": "*" },
    { "Effect": "Allow", "Action": ["iam:PassRole"], "Resource": "*" }
  ]
}
```

### 5. Destruir tudo (⚠️ faça sempre que terminar!)

```bash
bash scripts/destroy.sh
```

---

## 💰 Free Tier: o que é grátis e o que não é

| Serviço | Free Tier | Atenção |
|---|---|---|
| ECR | 500 MB/mês | Imagem ~50 MB → OK |
| ECS Cluster | Gratuito | O cluster em si é free |
| **Fargate** | **NÃO é grátis** | ~$0.01/h para 0.25vCPU |
| EC2 t2.micro | **750h/mês grátis** | Alternativa ao Fargate |
| S3 | 5 GB + 20k GET grátis | OK para estudo |
| CloudWatch | 5 GB logs grátis | Retenção em 7 dias |
| CloudFormation | **Gratuito** | Paga só pelos recursos |

### 📌 Para zero custo absoluto: use EC2 t2.micro

Fargate é a arquitetura moderna (serverless containers), mas não está no Free Tier.
Para estudar gastando R$0, substitua `LaunchType: FARGATE` por EC2 t2.micro no CloudFormation.

### 💡 Dicas para não se surpreender com a fatura

1. **Configure Budget Alert**: AWS Console → Billing → Budgets → crie alerta em $1
2. **Destrua depois de estudar**: `bash scripts/destroy.sh`
3. **Monitore**: `aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost`

---

## 🔍 Endpoints da API

| Método | Rota | Descrição |
|---|---|---|
| GET | `/` | Frontend |
| GET | `/health` | Health check (usado pelo ECS) |
| GET | `/api/info` | Info do container/ambiente |
| GET | `/api/tasks` | Lista de tarefas |
| PATCH | `/api/tasks/:id` | Alterna done/undone |

---

## 📚 Conceitos aprendidos neste projeto

- **Docker multi-stage build** → imagem pequena (~50 MB)
- **ECR** → registry privado de imagens Docker na AWS
- **ECS Fargate** → rodar containers sem gerenciar servidores
- **CloudFormation** → Infrastructure as Code (IaC)
- **GitLab CI/CD** → pipeline de deploy automático
- **IAM** → controle de acesso com least privilege
- **CloudWatch** → logs e monitoramento
- **S3** → armazenamento de objetos
- **VPC + Security Groups** → rede isolada e segura
