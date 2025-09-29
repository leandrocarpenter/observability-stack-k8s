FROM node:18-alpine

WORKDIR /app

# Copiar package.json (será criado pelo build)
COPY package*.json ./

# Instalar dependências
RUN npm install

# Copiar código da aplicação
COPY app.js ./

# Expor porta
EXPOSE 3000

# Comando para iniciar a aplicação
CMD ["node", "app.js"]