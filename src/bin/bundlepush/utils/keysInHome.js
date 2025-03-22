import path from 'path';
import os from 'os';
import fs from 'fs';
import { CONFIG_DIRECTORY } from '../config/variables.js';

const keysFile = path.join(os.homedir(), CONFIG_DIRECTORY, 'keys.json');

export async function loadKeyFromHome() {
  const content = await keysFileContent();
  return content?.keys[process.cwd()]?.key ?? null;
}

export async function saveKeyToHome(key) {
  let content = (await keysFileContent()) ?? {};
  if (!content.keys) {
    content.keys = {};
  }
  content.keys[process.cwd()] = { key };
  makeDirectoryIfNecessary();
  fs.writeFileSync(keysFile, JSON.stringify(content, null, 2));
}

function makeDirectoryIfNecessary() {
  const directory = path.join(os.homedir(), CONFIG_DIRECTORY);
  if (!fs.existsSync(directory)) {
    fs.mkdirSync(directory, { recursive: true });
  }
}

async function keysFileContent() {
  if (!fs.existsSync(keysFile)) {
    return null;
  }
  const contentString = fs.readFileSync(keysFile, 'utf8').trim();
  let content = null;
  try {
    content = JSON.parse(contentString);
  } catch (error) {}

  return content;
}
