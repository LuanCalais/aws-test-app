# ──────────────────────────────────────────────────────────────────
# STAGE 1 — deps
# Instala só as dependências de produção num layer separado.
FROM node:20-alpine AS deps

WORKDIR /app

COPY package*.json ./
RUN npm ci 

# ──────────────────────────────────────────────────────────────────
# STAGE 2 — builder (roda os testes antes de empacotar)
FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci

COPY src/ ./src/
COPY public/ ./public/

RUN npm test -- --passWithNoTests

# ──────────────────────────────────────────────────────────────────
# STAGE 3 — runner (imagem final, minimalista)
FROM node:20-alpine AS runner

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copia só o necessário do stage anterior
COPY --from=deps    /app/node_modules ./node_modules
COPY --from=builder /app/src          ./src
COPY --from=builder /app/public       ./public
COPY package.json   ./

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "src/app.js"]

