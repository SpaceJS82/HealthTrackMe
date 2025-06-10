const request = require('supertest');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

// Mock dependencies
jest.mock('../db/db', () => {
  function qbMock(methods = {}) {
    const qb = {};
    ['where', 'first', 'insert'].forEach(m => {
      qb[m] = jest.fn().mockReturnValue(qb);
    });
    Object.assign(qb, methods);
    return qb;
  }

  return jest.fn((table) => {
    if (table === 'user') {
      return qbMock({
        where: jest.fn().mockReturnThis(),
        first: jest.fn().mockResolvedValue({
          iduser: 1,
          username: 'test@example.com',
          password: '$2b$10$hashedPassword',
          name: 'Test User'
        }),
        insert: jest.fn().mockResolvedValue([1]),
      });
    }
    return qbMock();
  });
});

jest.mock('bcrypt', () => ({
  compare: jest.fn(),
  hash: jest.fn(),
}));

jest.mock('jsonwebtoken', () => ({
  sign: jest.fn(() => 'fake-jwt-token'),
  verify: jest.fn((token, secret) => {
    // Return decoded token synchronously
    return { id: 1, username: 'test@example.com' };
  }),
}));

// Import the router after mocking
const app = require('../index');
const db = require('../db/db');



describe('Auth API', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    process.env.JWT_SECRET = 'test-secret';
    
    // Reset JWT verify to default behavior (synchronous, no callback)
    jwt.verify.mockImplementation((token, secret) => {
      return { id: 1, username: 'test@example.com' };
    });
  }); // ← Missing closing brace and parenthesis

  describe('GET /check-connectivity', () => {
    it('should return 200', async () => {
      const res = await request(app).get('/check-connectivity');
      expect(res.statusCode).toBe(200);
    });
  });

  describe('POST /login', () => {
    it('should login with valid credentials', async () => {
      // Mock successful login
      db.mockImplementation((table) => {
        if (table === 'user') {
          return {
            where: jest.fn().mockResolvedValue([{
              iduser: 1,
              username: 'test@example.com',
              password: '$2b$10$hashedPassword',
              name: 'Test User'
            }])
          };
        }
      });
      bcrypt.compare.mockResolvedValue(true);

      const res = await request(app)
        .post('/login')
        .send({
          username: 'test@example.com',
          password: 'password123'
        });

      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('token');
      expect(res.body).toHaveProperty('user');
      expect(res.body.user.username).toBe('test@example.com');
    });

    it('should reject invalid username', async () => {
      // Mock user not found
      db.mockImplementation((table) => {
        if (table === 'user') {
          return {
            where: jest.fn().mockResolvedValue([]) // Empty array = user not found
          };
        }
      });

      const res = await request(app)
        .post('/login')
        .send({
          username: 'nonexistent@example.com',
          password: 'password123'
        });

      expect(res.statusCode).toBe(404);
      expect(res.text).toBe('User not found');
    });

    it('should reject invalid password', async () => {
      // Mock user found but wrong password
      db.mockImplementation((table) => {
        if (table === 'user') {
          return {
            where: jest.fn().mockResolvedValue([{
              iduser: 1,
              username: 'test@example.com',
              password: '$2b$10$hashedPassword',
              name: 'Test User'
            }])
          };
        }
      });
      bcrypt.compare.mockResolvedValue(false);

      const res = await request(app)
        .post('/login')
        .send({
          username: 'test@example.com',
          password: 'wrongpassword'
        });

      expect(res.statusCode).toBe(401);
      expect(res.text).toBe('Incorrect password');
    });
  });

  describe('POST /register', () => {
    it('should register new user with valid email', async () => {
      // Mock user doesn't exist
      db.mockImplementation((table) => {
        if (table === 'user') {
          return {
            where: jest.fn().mockResolvedValue([]), // No existing user
            insert: jest.fn().mockResolvedValue([1])
          };
        }
      });
      bcrypt.hash.mockResolvedValue('$2b$10$hashedPassword');

      const res = await request(app)
        .post('/register')
        .send({
          username: 'newuser@example.com',
          password: 'password123',
          name: 'New User'
        });

      expect(res.statusCode).toBe(201);
      expect(res.text).toBe('User registered successfully');
      expect(bcrypt.hash).toHaveBeenCalledWith('password123', 10);
    });

    it('should reject invalid email format', async () => {
      const res = await request(app)
        .post('/register')
        .send({
          username: 'invalidemail',
          password: 'password123',
          name: 'New User'
        });

      expect(res.statusCode).toBe(400);
      expect(res.text).toBe('Invalid email address');
    });

    it('should reject existing username', async () => {
      // Mock user already exists
      db.mockImplementation((table) => {
        if (table === 'user') {
          return {
            where: jest.fn().mockResolvedValue([{
              iduser: 1,
              username: 'existing@example.com'
            }])
          };
        }
      });

      const res = await request(app)
        .post('/register')
        .send({
          username: 'existing@example.com',
          password: 'password123',
          name: 'New User'
        });

      expect(res.statusCode).toBe(409);
      expect(res.text).toBe('Username already taken');
    });
  });

  describe('GET /check-auth', () => {
    it('should require authentication token', async () => {
      const res = await request(app).get('/check-auth');
      expect(res.statusCode).toBe(401);
    });

    it('should return user info with valid token', async () => {
      // Mock user exists in database
      db.mockImplementation((table) => {
        if (table === 'user') {
          return {
            where: jest.fn().mockReturnThis(),
            first: jest.fn().mockResolvedValue({
              iduser: 1,
              username: 'test@example.com',
              name: 'Test User'
            })
          };
        }
      });

      const res = await request(app)
        .get('/check-auth')
        .set('Authorization', 'Bearer valid-token');

      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('user');
      expect(res.body.user.username).toBe('test@example.com');
    });

    it('should reject invalid token', async () => {
  jwt.verify.mockImplementation((token, secret) => {
    throw new Error('Invalid token');
  });

  const res = await request(app)
    .get('/check-auth')
    .set('Authorization', 'Bearer invalid-token');

  expect(res.statusCode).toBe(403);
  expect(res.body).toHaveProperty('error');
});

    it('should reject when user no longer exists', async () => {
      // Mock user not found in database
      db.mockImplementation((table) => {
        if (table === 'user') {
          return {
            where: jest.fn().mockReturnThis(),
            first: jest.fn().mockResolvedValue(null) // User not found
          };
        }
      });

      const res = await request(app)
        .get('/check-auth')
        .set('Authorization', 'Bearer valid-token');

      expect(res.statusCode).toBe(403);
      expect(res.body.error).toBe('User no longer exists');
    });
  });
});