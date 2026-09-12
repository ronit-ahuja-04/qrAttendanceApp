const request = require('supertest');
const app = require('../index');
const { seedTestDb } = require('./testDb');

beforeAll(async () => {
  await seedTestDb();
});

describe('Authentication API', () => {
  it('should allow faculty to login with valid credentials', async () => {
    const res = await request(app)
      .post('/login')
      .send({ email: 'fac@test.com', password: 'facpass' });
    
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveProperty('id', 'fac1');
    expect(res.body).toHaveProperty('role', 'faculty');
  });

  it('should allow students to login with valid credentials', async () => {
    const res = await request(app)
      .post('/login')
      .send({ email: 'stud@test.com', password: 'studpass' });
    
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveProperty('id', 'stud1');
    expect(res.body).toHaveProperty('role', 'student');
  });

  it('should reject login with invalid credentials', async () => {
    const res = await request(app)
      .post('/login')
      .send({ email: 'fac@test.com', password: 'wrongpassword' });
    
    expect(res.statusCode).toEqual(401);
    expect(res.body).toHaveProperty('error');
  });

  it('should reject login for non-existent user', async () => {
    const res = await request(app)
      .post('/login')
      .send({ email: 'nobody@test.com', password: 'password' });
    
    expect(res.statusCode).toEqual(401);
  });

  it('should block SQL injection in email', async () => {
    const res = await request(app)
      .post('/login')
      .send({ email: "admin' OR '1'='1", password: "password" });
    
    expect(res.statusCode).toEqual(401);
  });
});
