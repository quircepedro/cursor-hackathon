module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'scope-enum': [
      2,
      'always',
      [
        'mobile',
        'backend',
        'auth',
        'audio',
        'transcription',
        'analysis',
        'clips',
        'history',
        'subscriptions',
        'notifications',
        'infra',
        'docs',
        'ci',
        'deps',
        'config',
      ],
    ],
    'subject-case': [2, 'always', 'lower-case'],
    'header-max-length': [2, 'always', 100],
  },
};
