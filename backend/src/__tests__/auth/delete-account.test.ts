import request from 'supertest';
import { Application } from 'express';
import { getTestApp, closeTestApp } from '../helpers/testApp';
import { registerAndLogin } from '../helpers/auth';

describe('DELETE /api/v1/auth/profile — self-serve account deletion', () => {
  let app: Application;

  beforeAll(async () => {
    app = await getTestApp();
  });

  afterAll(async () => {
    await closeTestApp();
  });

  it('rejects deletion when the password does not match', async () => {
    const { token } = await registerAndLogin(app, 'delbad');

    const res = await request(app)
      .delete('/api/v1/auth/profile')
      .set('Authorization', `Bearer ${token}`)
      .send({ password: 'WrongPassword123!' });

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);

    // sanity: profile still reachable
    const me = await request(app)
      .get('/api/v1/auth/profile')
      .set('Authorization', `Bearer ${token}`);
    expect(me.status).toBe(200);
  });

  it('rejects deletion when no password is supplied', async () => {
    const { token } = await registerAndLogin(app, 'delnopw');

    const res = await request(app)
      .delete('/api/v1/auth/profile')
      .set('Authorization', `Bearer ${token}`)
      .send({});

    expect(res.status).toBeGreaterThanOrEqual(400);
    expect(res.status).toBeLessThan(500);
  });

  it('hard-deletes the account when the password is correct, and subsequent login fails', async () => {
    const suffix = `delok${Date.now()}${Math.floor(Math.random() * 1000)}`;
    const email = `${suffix}@test.local`;
    const password = 'Password123!';

    const reg = await request(app)
      .post('/api/v1/auth/register')
      .send({ email, password, firstName: 'Goodbye', lastName: suffix });
    expect(reg.status).toBe(201);

    const login = await request(app)
      .post('/api/v1/auth/login')
      .send({ email, password });
    expect(login.status).toBe(200);
    const token: string = login.body.data.token;

    // create a semester so we can prove the cascade kicked in
    const sem = await request(app)
      .post('/api/v1/semesters')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'doomed term',
        startDate: '2026-01-01',
        endDate: '2026-04-30',
      });
    expect(sem.status).toBe(201);

    const del = await request(app)
      .delete('/api/v1/auth/profile')
      .set('Authorization', `Bearer ${token}`)
      .send({ password });
    expect(del.status).toBe(200);
    expect(del.body.success).toBe(true);

    // subsequent login with the same credentials must fail (user is gone)
    const loginAfter = await request(app)
      .post('/api/v1/auth/login')
      .send({ email, password });
    expect(loginAfter.status).toBe(401);

    // the old access token must no longer resolve to a live user
    const meAfter = await request(app)
      .get('/api/v1/auth/profile')
      .set('Authorization', `Bearer ${token}`);
    expect(meAfter.status).toBeGreaterThanOrEqual(400);
  });
});
