const express = require("express");
const path = require("path");
const os = require("os");

const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, "../public")));

app.get("/health", (req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

app.get("/api/info", (req, res) => {
  res.json({
    hostname: os.hostname(), // ID do container ECS
    platform: os.platform(),
    arch: os.arch(),
    uptime: Math.floor(os.uptime()) + "s",
    memory: {
      total: (os.totalmem() / 1024 / 1024).toFixed(0) + " MB",
      free: (os.freemem() / 1024 / 1024).toFixed(0) + " MB",
    },
    env: process.env.APP_ENV || "local",
    version: process.env.APP_VERSION || "1.0.0",
    region: process.env.AWS_REGION || "não definida",
  });
});

const tasks = [
  { id: 1, title: "Aprender Docker", done: true },
  { id: 2, title: "Fazer deploy na AWS", done: false },
  { id: 3, title: "Configurar GitLab CI", done: false },
  { id: 4, title: "Usar Free Tier 100%", done: false },
];

app.get("/api/tasks", (req, res) => res.json(tasks));

app.patch("/api/tasks/:id", (req, res) => {
  const task = tasks.find((t) => t.id === Number(req.params.id));
  if (!task) return res.status(404).json({ error: "Task não encontrada" });
  task.done = !task.done;
  res.json(task);
});

app.get("*", (req, res) => {
  res.sendFile(path.join(__dirname, "../public/index.html"));
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(
    `🚀 App rodando na porta ${PORT} | env: ${process.env.APP_ENV || "local"}`,
  );
});

module.exports = app;
