/** @type {import('jest').Config} */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['**/__tests__/**/*.test.ts'],
  testPathIgnorePatterns: ['/node_modules/', '/dist/', '/__tests__/helpers/'],
  // Tests share a real MySQL DB — run them sequentially to keep state predictable.
  maxWorkers: 1,
  // Each test file shares a TypeORM DataSource via getTestApp/closeTestApp.
  // Force open-handle detection so a leaked connection fails loudly.
  detectOpenHandles: true,
  testTimeout: 15000,
};
