import request from 'supertest';
import { Application } from 'express';
import { getTestApp, closeTestApp } from '../helpers/testApp';
import { registerAndLogin } from '../helpers/auth';

describe('POST /api/v1/sessions/start — ad-hoc', () => {
  let app: Application;
  let token: string;

  beforeAll(async () => {
    app = await getTestApp();
    const auth = await registerAndLogin(app, 'adhoc');
    token = auth.token;
  });

  afterAll(async () => {
    await closeTestApp();
  });

  it('starts an ad-hoc session with just activityName', async () => {
    const res = await request(app)
      .post('/api/v1/sessions/start')
      .set('Authorization', `Bearer ${token}`)
      .send({ activityName: 'reading the brothers karamazov' });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.subjectId).toBeNull();
    expect(res.body.data.semesterId).toBeNull();
    expect(res.body.data.activityName).toBe('reading the brothers karamazov');
    expect(res.body.data.status).toBe('ACTIVE');

    // Cleanup so next test isn't blocked by an active session
    const stopRes = await request(app)
      .post(`/api/v1/sessions/${res.body.data.id}/stop`)
      .set('Authorization', `Bearer ${token}`)
      .send();
    expect(stopRes.status).toBe(200);
  });

  it('rejects starting with neither subjectId nor activityName', async () => {
    const res = await request(app)
      .post('/api/v1/sessions/start')
      .set('Authorization', `Bearer ${token}`)
      .send({});

    expect(res.status).toBe(400);
  });

  it('rejects starting with both subjectId and activityName', async () => {
    const res = await request(app)
      .post('/api/v1/sessions/start')
      .set('Authorization', `Bearer ${token}`)
      .send({
        subjectId: '00000000-0000-0000-0000-000000000000',
        activityName: 'something',
      });

    expect(res.status).toBe(400);
  });

  it('trims activityName and rejects whitespace-only', async () => {
    const res = await request(app)
      .post('/api/v1/sessions/start')
      .set('Authorization', `Bearer ${token}`)
      .send({ activityName: '   ' });

    expect(res.status).toBe(400);
  });
});
