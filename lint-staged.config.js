module.exports = {
  'apps/backend/**/*.ts': [
    'eslint --fix',
    'prettier --write',
  ],
  'packages/**/*.ts': [
    'eslint --fix',
    'prettier --write',
  ],
  '*.{json,md,yaml,yml}': [
    'prettier --write',
  ],
  '*.sh': [
    'prettier --write',
  ],
};
