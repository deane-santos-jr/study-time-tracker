import request from 'supertest';
import { Application } from 'express';
import { getTestApp, closeTestApp } from '../helpers/testApp';
import { registerAndLogin } from '../helpers/auth';

describe('DELETE /api/v1/subjects/:id — orphan flow', () => {
  let app: Application;
  let token: string;

  beforeAll(async () => {
    app = await getTestApp();
    const auth = await registerAndLogin(app, 'orphan');
    token = auth.token;
  });

  afterAll(async () => {
    await closeTestApp();
  });

  it('orphans sessions to ad-hoc when deleting a subject with history', async () => {
    const sem = await request(app)
      .post('/api/v1/semesters')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'fall 2026',
        startDate: '2026-08-01',
        endDate: '2026-12-15',
      });
    expect(sem.status).toBe(201);

    const subj = await request(app)
      .post('/api/v1/subjects')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'calculus 101',
        color: '#A23B5C',
        semesterId: sem.body.data.id,
      });
    expect(subj.status).toBe(201);

    const startRes = await request(app)
      .post('/api/v1/sessions/start')
      .set('Authorization', `Bearer ${token}`)
      .send({ subjectId: subj.body.data.id });
    expect(startRes.status).toBe(201);

    const stopRes = await request(app)
      .post(`/api/v1/sessions/${startRes.body.data.id}/stop`)
      .set('Authorization', `Bearer ${token}`)
      .send();
    expect(stopRes.status).toBe(200);

    const del = await request(app)
      .delete(`/api/v1/subjects/${subj.body.data.id}`)
      .set('Authorization', `Bearer ${token}`);

    expect(del.status).toBe(200);
    expect(del.body.data.orphanedSessionCount).toBe(1);

    const sessions = await request(app)
      .get('/api/v1/sessions')
      .set('Authorization', `Bearer ${token}`);
    expect(sessions.status).toBe(200);

    const orphaned = sessions.body.data.find(
      (s: { id: string }) => s.id === startRes.body.data.id
    );
    expect(orphaned).toBeDefined();
    expect(orphaned.subjectId).toBeNull();
    expect(orphaned.semesterId).toBeNull();
    expect(orphaned.activityName).toBe('calculus 101');
  });

  it('clean-deletes a subject with zero sessions', async () => {
    const sem = await request(app)
      .post('/api/v1/semesters')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'spring 2027',
        startDate: '2027-01-15',
        endDate: '2027-05-15',
      });
    const subj = await request(app)
      .post('/api/v1/subjects')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'history',
        color: '#3E5C7A',
        semesterId: sem.body.data.id,
      });

    const del = await request(app)
      .delete(`/api/v1/subjects/${subj.body.data.id}`)
      .set('Authorization', `Bearer ${token}`);

    expect(del.status).toBe(200);
    expect(del.body.data.orphanedSessionCount).toBe(0);
  });
});
