const request = require('supertest');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

// Mock the database module
jest.mock('../src/config/database', () => ({
  query: jest.fn(),
  getConnection: jest.fn(() => ({
    query: jest.fn(),
    release: jest.fn()
  }))
}));

const app = require('../src/app');
const db = require('../src/config/database');

describe('Authentication Endpoints', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('POST /api/auth/register', () => {
    it('should register a new user successfully', async () => {
      // Mock database responses
      db.query
        .mockResolvedValueOnce([]) // Check if user exists
        .mockResolvedValueOnce([{ insertId: 1 }]); // Insert user

      const userData = {
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
        role: 'user'
      };

      const response = await request(app)
        .post('/api/auth/register')
        .send(userData)
        .expect(201);

      expect(response.body).toHaveProperty('token');
      expect(response.body).toHaveProperty('userId');
      expect(response.body.message).toBe('User registered successfully');
    });

    it('should return 400 if user already exists', async () => {
      // Mock user already exists
      db.query.mockResolvedValueOnce([{ id: 1, email: 'test@example.com' }]);

      const userData = {
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
        role: 'user'
      };

      const response = await request(app)
        .post('/api/auth/register')
        .send(userData)
        .expect(400);

      expect(response.body.message).toBe('User already exists');
    });

    it('should return 400 for invalid email format', async () => {
      const userData = {
        email: 'invalid-email',
        password: 'password123',
        name: 'Test User',
        role: 'user'
      };

      const response = await request(app)
        .post('/api/auth/register')
        .send(userData)
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });
  });

  describe('POST /api/auth/login', () => {
    it('should login user with valid credentials', async () => {
      const hashedPassword = await bcrypt.hash('password123', 10);
      
      // Mock user found in database
      db.query.mockResolvedValueOnce([{
        id: 1,
        email: 'test@example.com',
        password: hashedPassword,
        role: 'user',
        name: 'Test User'
      }]);

      const loginData = {
        email: 'test@example.com',
        password: 'password123'
      };

      const response = await request(app)
        .post('/api/auth/login')
        .send(loginData)
        .expect(200);

      expect(response.body).toHaveProperty('token');
      expect(response.body).toHaveProperty('userId');
      expect(response.body.message).toBe('Login successful');
    });

    it('should return 401 for invalid credentials', async () => {
      // Mock user not found
      db.query.mockResolvedValueOnce([]);

      const loginData = {
        email: 'test@example.com',
        password: 'wrongpassword'
      };

      const response = await request(app)
        .post('/api/auth/login')
        .send(loginData)
        .expect(401);

      expect(response.body.message).toBe('Invalid credentials');
    });
  });

  describe('GET /health', () => {
    it('should return health status', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.body.status).toBe('OK');
      expect(response.body.message).toBe('Auth backend is running');
    });
  });
});

describe('JWT Token Validation', () => {
  it('should validate JWT token correctly', () => {
    const payload = { userId: 1, email: 'test@example.com' };
    const secret = process.env.JWT_SECRET || 'test-secret';
    
    const token = jwt.sign(payload, secret, { expiresIn: '1h' });
    const decoded = jwt.verify(token, secret);
    
    expect(decoded.userId).toBe(payload.userId);
    expect(decoded.email).toBe(payload.email);
  });

  it('should reject invalid JWT token', () => {
    const invalidToken = 'invalid.token.here';
    const secret = process.env.JWT_SECRET || 'test-secret';
    
    expect(() => {
      jwt.verify(invalidToken, secret);
    }).toThrow();
  });
});