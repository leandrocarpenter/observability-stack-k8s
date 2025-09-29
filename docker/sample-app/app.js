const express = require('express');
const promClient = require('prom-client');

const app = express();
const port = 3000;

// Configurar métricas Prometheus
const collectDefaultMetrics = promClient.collectDefaultMetrics;
collectDefaultMetrics({ timeout: 5000 });

const httpRequestsTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route']
});

// Middleware para métricas
app.use((req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpRequestsTotal.inc({
      method: req.method,
      route: req.route?.path || req.path,
      status_code: res.statusCode
    });
    httpRequestDuration.observe({
      method: req.method,
      route: req.route?.path || req.path
    }, duration);
  });
  
  next();
});

// Rotas
app.get('/', (req, res) => {
  res.json({ 
    message: 'Hello from Node.js observability demo!', 
    timestamp: new Date(),
    version: '1.0.0'
  });
});

app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    uptime: process.uptime(),
    memory: process.memoryUsage()
  });
});

app.get('/metrics', (req, res) => {
  res.set('Content-Type', promClient.register.contentType);
  res.end(promClient.register.metrics());
});

// Rota que simula erro ocasional
app.get('/random', (req, res) => {
  if (Math.random() < 0.1) {
    res.status(500).json({ error: 'Random error occurred' });
  } else {
    res.json({ 
      random: Math.random(), 
      timestamp: new Date() 
    });
  }
});

// Rota para simular carga
app.get('/load', (req, res) => {
  const start = Date.now();
  // Simular processamento
  while (Date.now() - start < 100) {
    // Busy wait
  }
  res.json({ message: 'Load test completed', duration: Date.now() - start });
});

app.listen(port, () => {
  console.log(`🚀 Sample Node.js app running on port ${port}`);
  console.log(`📊 Metrics available at http://localhost:${port}/metrics`);
});