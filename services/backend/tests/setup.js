process.env.NODE_ENV = 'test';

jest.mock('firebase-admin', () => ({
  credential: {
    cert: jest.fn(),
  },
  initializeApp: jest.fn(),
  messaging: jest.fn(() => ({
    send: jest.fn(() => Promise.resolve('mock-message-id')),
  })),
}));
