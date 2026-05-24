import request from 'supertest';
import { Application } from 'express';

/**
 * Register + log in a fresh user. Email is randomized so parallel tests
 * don't collide. Returns the user id and access token; the token is
 * suitable for `Authorization: Bearer <token>` on subsequent requests.
 */
export async function registerAndLogin(
  app: Application,
  prefix = 't'
): Promise<{ userId: string; token: string }> {
  const suffix = `${prefix}${Date.now()}${Math.floor(Math.random() * 1000)}`;
  const email = `${suffix}@test.local`;
  const password = 'Password123!';

  const reg = await request(app)
    .post('/api/v1/auth/register')
    .send({
      email,
      password,
      firstName: 'Test',
      lastName: suffix,
    });

  if (reg.status !== 201) {
    throw new Error(`Register failed: ${reg.status} ${JSON.stringify(reg.body)}`);
  }

  const login = await request(app)
    .post('/api/v1/auth/login')
    .send({ email, password });

  if (login.status !== 200) {
    throw new Error(`Login failed: ${login.status} ${JSON.stringify(login.body)}`);
  }

  return {
    userId: login.body.data.user.id,
    token: login.body.data.token,
  };
}
