import request from 'supertest';
import { Application } from 'express';
import { getTestApp, closeTestApp } from '../helpers/testApp';
import { registerAndLogin } from '../helpers/auth';

describe('PUT /api/v1/semesters/:id { isActive: true } — single active invariant', () => {
  let app: Application;
  let token: string;

  beforeAll(async () => {
    app = await getTestApp();
    const auth = await registerAndLogin(app, 'semact');
    token = auth.token;
  });

  afterAll(async () => {
    await closeTestApp();
  });

  it('deactivates the previously-active semester when another is activated', async () => {
    const a = await request(app)
      .post('/api/v1/semesters')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'term a',
        startDate: '2026-01-01',
        endDate: '2026-04-30',
      });
    const b = await request(app)
      .post('/api/v1/semesters')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'term b',
        startDate: '2026-05-01',
        endDate: '2026-08-30',
      });

    await request(app)
      .put(`/api/v1/semesters/${a.body.data.id}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ isActive: true });

    await request(app)
      .put(`/api/v1/semesters/${b.body.data.id}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ isActive: true });

    const list = await request(app)
      .get('/api/v1/semesters')
      .set('Authorization', `Bearer ${token}`);

    const byId = new Map<string, { id: string; isActive: boolean }>(
      list.body.data.map((s: { id: string; isActive: boolean }) => [s.id, s])
    );
    expect(byId.get(a.body.data.id)?.isActive).toBe(false);
    expect(byId.get(b.body.data.id)?.isActive).toBe(true);

    const activeCount = list.body.data.filter(
      (s: { isActive: boolean }) => s.isActive
    ).length;
    expect(activeCount).toBe(1);
  });
});
