const request = require('supertest');
const app     = require('../src/app');

describe('Health Check', () => {
  it('GET /health → 200 com status ok', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.timestamp).toBeDefined();
  });
});

describe('API /info', () => {
  it('retorna informações do ambiente', async () => {
    const res = await request(app).get('/api/info');
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('hostname');
    expect(res.body).toHaveProperty('memory');
    expect(res.body.memory).toHaveProperty('total');
  });
});

describe('API /tasks', () => {
  it('retorna lista de tasks', async () => {
    const res = await request(app).get('/api/tasks');
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThan(0);
  });

  it('PATCH /tasks/:id alterna done', async () => {
    const antes = await request(app).get('/api/tasks');
    const task  = antes.body[1]; // task 2 (inicialmente false)
    const res   = await request(app).patch(`/api/tasks/${task.id}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.done).toBe(!task.done);
  });

  it('PATCH /tasks/999 → 404', async () => {
    const res = await request(app).patch('/api/tasks/999');
    expect(res.statusCode).toBe(404);
  });
});
