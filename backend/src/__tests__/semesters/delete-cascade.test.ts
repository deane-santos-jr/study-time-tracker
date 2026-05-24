import request from 'supertest';
import { Application } from 'express';
import { getTestApp, closeTestApp } from '../helpers/testApp';
import { registerAndLogin } from '../helpers/auth';

describe('DELETE /api/v1/semesters/:id — cascade orphan', () => {
  let app: Application;
  let token: string;

  beforeAll(async () => {
    app = await getTestApp();
    const auth = await registerAndLogin(app, 'semdel');
    token = auth.token;
  });

  afterAll(async () => {
    await closeTestApp();
  });

  it('cascades subject deletion and orphans sessions', async () => {
    const sem = await request(app)
      .post('/api/v1/semesters')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'summer 2026',
        startDate: '2026-06-01',
        endDate: '2026-08-15',
      });

    const s1 = await request(app)
      .post('/api/v1/subjects')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'a', color: '#7A8C3E', semesterId: sem.body.data.id });
    const s2 = await request(app)
      .post('/api/v1/subjects')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'b', color: '#E8A33D', semesterId: sem.body.data.id });

    for (const subjId of [s1.body.data.id, s2.body.data.id]) {
      const st = await request(app)
        .post('/api/v1/sessions/start')
        .set('Authorization', `Bearer ${token}`)
        .send({ subjectId: subjId });
      await request(app)
        .post(`/api/v1/sessions/${st.body.data.id}/stop`)
        .set('Authorization', `Bearer ${token}`)
        .send();
    }

    await request(app)
      .put(`/api/v1/semesters/${sem.body.data.id}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ isActive: false });

    const del = await request(app)
      .delete(`/api/v1/semesters/${sem.body.data.id}`)
      .set('Authorization', `Bearer ${token}`);

    expect(del.status).toBe(200);
    expect(del.body.data.orphanedSubjectCount).toBe(2);
    expect(del.body.data.orphanedSessionCount).toBe(2);

    const sessions = await request(app)
      .get('/api/v1/sessions')
      .set('Authorization', `Bearer ${token}`);
    const adhocNames = sessions.body.data
      .filter((s: { activityName: string | null }) => s.activityName !== null)
      .map((s: { activityName: string }) => s.activityName)
      .sort();
    expect(adhocNames).toEqual(['a', 'b']);
  });

  it('rejects deleting an active semester', async () => {
    const sem = await request(app)
      .post('/api/v1/semesters')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'active-blocked',
        startDate: '2026-09-01',
        endDate: '2026-12-15',
      });

    await request(app)
      .put(`/api/v1/semesters/${sem.body.data.id}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ isActive: true });

    const del = await request(app)
      .delete(`/api/v1/semesters/${sem.body.data.id}`)
      .set('Authorization', `Bearer ${token}`);

    expect(del.status).toBe(400);
  });
});
