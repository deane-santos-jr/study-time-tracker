import request from 'supertest';
import { Application } from 'express';
import { getTestApp, closeTestApp } from '../helpers/testApp';
import { registerAndLogin } from '../helpers/auth';

describe('GET /api/v1/semesters/:id/stats', () => {
  let app: Application;
  let token: string;

  beforeAll(async () => {
    app = await getTestApp();
    const auth = await registerAndLogin(app, 'stats');
    token = auth.token;
  });

  afterAll(async () => {
    await closeTestApp();
  });

  it('returns subject + session + total time for a semester', async () => {
    const sem = await request(app)
      .post('/api/v1/semesters')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'stats term',
        startDate: '2026-09-01',
        endDate: '2026-12-15',
      });

    const subj = await request(app)
      .post('/api/v1/subjects')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 's',
        color: '#A23B5C',
        semesterId: sem.body.data.id,
      });

    const st = await request(app)
      .post('/api/v1/sessions/start')
      .set('Authorization', `Bearer ${token}`)
      .send({ subjectId: subj.body.data.id });
    // MySQL DATETIME(0) rounds fractional seconds half-up, so the apparent
    // elapsed seconds can drift by ±1. Sleep 2.5s so floor(elapsed) is
    // reliably >= 1 even after worst-case rounding.
    await new Promise((r) => setTimeout(r, 2500));
    await request(app)
      .post(`/api/v1/sessions/${st.body.data.id}/stop`)
      .set('Authorization', `Bearer ${token}`)
      .send();

    const stats = await request(app)
      .get(`/api/v1/semesters/${sem.body.data.id}/stats`)
      .set('Authorization', `Bearer ${token}`);

    expect(stats.status).toBe(200);
    expect(stats.body.data.subjectCount).toBe(1);
    expect(stats.body.data.sessionCount).toBe(1);
    expect(stats.body.data.totalSeconds).toBeGreaterThanOrEqual(1);
  });

  it('404s on unknown semester id', async () => {
    const res = await request(app)
      .get('/api/v1/semesters/00000000-0000-0000-0000-000000000000/stats')
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(404);
  });
});
