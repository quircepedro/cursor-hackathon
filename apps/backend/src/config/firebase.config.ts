import { registerAs } from '@nestjs/config';

function parsePrivateKey(raw?: string): string {
  if (!raw) return '';
  // Strip surrounding quotes if present
  let key = raw.trim();
  if ((key.startsWith('"') && key.endsWith('"')) || (key.startsWith("'") && key.endsWith("'"))) {
    key = key.slice(1, -1);
  }
  // Replace literal \n sequences with real newlines
  key = key.replace(/\\n/g, '\n');
  return key;
}

export default registerAs('firebase', () => ({
  projectId: process.env.FIREBASE_PROJECT_ID,
  clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
  privateKey: parsePrivateKey(process.env.FIREBASE_PRIVATE_KEY),
}));
