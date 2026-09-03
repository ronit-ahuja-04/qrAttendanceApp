module.exports = {
  testEnvironment: 'node',
  setupFilesAfterEnv: ['./tests/setup.js'],
  moduleNameMapper: {
    '^uuid$': '<rootDir>/tests/mocks/uuid.js'
  }
};
