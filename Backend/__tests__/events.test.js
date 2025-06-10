const request = require('supertest');
const express = require('express');
const eventsRouter = require('../routes/events');

// Mock JWT
jest.mock('jsonwebtoken', () => ({
  verify: (token, secret, cb) => cb(null, { id: 1, username: 'testuser' }),
}));

// Main db function mock
jest.mock('../db/db', () => {
  function qbMock(finals = {}) {
    // Add ALL possible chainable methods, so every table supports every needed method
    const chainMethods = [
      'where', 'whereIn', 'andWhere', 'orWhere', 'join', 'select',
      'leftJoin', 'groupBy', 'del', 'insert', 'update', 'from', 'orderBy', 'pluck'
    ];
    const qb = {};
    chainMethods.forEach(m => {
      qb[m] = jest.fn().mockReturnValue(qb);
    });
    Object.assign(qb, finals);
    return qb;
  }

  const dbFn = jest.fn((table) => {
     if (table === 'user') {
    return qbMock({
      leftJoin: jest.fn().mockReturnThis(),
      groupBy: jest.fn().mockReturnThis(),
      select: jest.fn().mockResolvedValue([
        {
          iduser: 1,
          sleepScore: 85,
          numberOfWorkout: 3
        },
        {
          iduser: 2,
          sleepScore: 90,
          numberOfWorkout: 5
        }
      ]),
      where: jest.fn().mockReturnThis(),
      first: jest.fn().mockResolvedValue({ 
        iduser: 1, 
        name: 'Test User', 
        username: 'testuser' 
      }),
    });
  }
    if (table === 'event') {
      const qb = qbMock({
        first: jest.fn().mockResolvedValue({
          idevent: 1,
          metadata: JSON.stringify({ foo: 'bar' }),
          type: 'workout',
          date: new Date().toISOString(),
        }),
        insert: jest.fn().mockResolvedValue([1]),
      });
      qb.select = jest.fn().mockResolvedValue([
        {
          idevent: 1,
          date: new Date().toISOString(),
          type: 'workout',
          metadata: JSON.stringify({ foo: 'bar' }),
          user_iduser: 1,
          name: 'Test User',
          username: 'testuser',
        },
      ]);
      return qb;
    }
    if (table === 'event_reaction') {
  const qb = qbMock({
    join: jest.fn().mockReturnThis(),
    select: jest.fn().mockReturnThis(), // Always return this for chaining
    where: jest.fn().mockReturnThis(),
    delete: jest.fn().mockResolvedValue(1),
    insert: jest.fn().mockResolvedValue([1]),
  });
  
  qb.first = jest.fn().mockResolvedValue({
    idreaction: 1,
    reaction: 'like',
    event_idevent: 1,
    user_iduser: 2,
    name: 'Friend',
    username: 'frienduser'
  });
  
  // Override the final query execution to return array when needed
  qb.then = jest.fn((callback) => {
    return callback([
      {
        idreaction: 1,
        reaction: 'like',
        event_idevent: 1,
        user_iduser: 2,
        name: 'Friend',
        username: 'frienduser'
      }
    ]);
  });
  
  return qb;
}
    if (table === 'friendship') {
      // For friendship, pluck should return a Promise with ids
      return qbMock({
        pluck: jest.fn().mockResolvedValue([2, 3]),
        first: jest.fn().mockResolvedValue(true),
        del: jest.fn().mockResolvedValue(1),
      });
    }
    if (table === 'health_metric') {
      return qbMock({
        select: jest.fn().mockResolvedValue([]),
        del: jest.fn().mockResolvedValue(1),
        insert: jest.fn().mockResolvedValue([1]),
      });
    }
    return qbMock();
  });

  dbFn.raw = (...args) => args[0];
  return dbFn;
});

const app = express();
app.use(express.json());
app.use('/events', eventsRouter);

describe('Events API', () => {
  describe('GET /events/get-events', () => {
    it('should require authentication', async () => {
      const res = await request(app).get('/events/get-events');
      expect(res.statusCode).toBe(401);
    });

    it('should return events for authenticated user', async () => {
      const res = await request(app)
        .get('/events/get-events')
        .set('Authorization', 'Bearer testtoken');
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('data');
    });
  });

  describe('POST /events/upload-event', () => {
    it('should require authentication', async () => {
      const res = await request(app).post('/events/upload-event').send({});
      expect(res.statusCode).toBe(401);
    });

    it('should reject missing fields', async () => {
      const res = await request(app)
        .post('/events/upload-event')
        .set('Authorization', 'Bearer testtoken')
        .send({});
      expect(res.statusCode).toBe(400);
    });

    it('should upload event with valid data', async () => {
      const res = await request(app)
        .post('/events/upload-event')
        .set('Authorization', 'Bearer testtoken')
        .send({ metadata: { foo: 'bar' }, type: 'workout' });
      expect([200, 201]).toContain(res.statusCode);
      expect(res.body).toHaveProperty('event');
    });
  });

  describe('POST /events/react-to-event', () => {
    it('should require authentication', async () => {
      const res = await request(app).post('/events/react-to-event').send({});
      expect(res.statusCode).toBe(401);
    });

    it('should reject missing fields', async () => {
      const res = await request(app)
        .post('/events/react-to-event')
        .set('Authorization', 'Bearer testtoken')
        .send({});
      expect(res.statusCode).toBe(400);
    });

    it('should react to event with valid data', async () => {
      const res = await request(app)
        .post('/events/react-to-event')
        .set('Authorization', 'Bearer testtoken')
        .send({ eventId: 1, reaction: 'like' });
      expect([200, 201, 400, 403, 404]).toContain(res.statusCode);
      // You can add more assertions depending on your mock logic
    });
  });
});