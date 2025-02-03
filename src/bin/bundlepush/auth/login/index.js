import inquirer from 'inquirer';
import open from 'open';
import { API_KEYS_URL, BUNDLEPUSH_API_KEY } from '../../config/variables.js';
import { loadKeyFromHome, saveKeyToHome } from '../../utils/keysInHome.js';
import { fetchKeyData } from '../../utils/fetchKeyData.js';

export async function handleAuthLogin() {
  const result = await checkCurrentAuthState();

  if (result === 'FINISH') {
    return;
  }

  if (result === 'FINISH_WITH_ERROR') {
    process.exit(1);
  }

  if (result === 'PROCEED') {
    await startLoginFlow();
  }
}

async function checkCurrentAuthState() {
  // 1. Check if an ENV variable key exists
  if (BUNDLEPUSH_API_KEY) {
    const keyData = await fetchKeyData(BUNDLEPUSH_API_KEY);
    if (keyData) {
      console.log(`✓ You are authenticated in ${keyData.organization.name}.`);
      return 'FINISH';
    } else {
      console.log('The provided key in environment variable is invalid.');
      return 'FINISH_WITH_ERROR';
    }
  } else {
    // 2. If no ENV key, check if we have a saved key in the home directory
    const savedKey = await loadKeyFromHome();
    const keyData = savedKey ? await fetchKeyData(savedKey) : null;
    if (keyData) {
      console.log(
        `✓ You are already authenticated in ${keyData.organization.name}.`
      );
      return 'FINISH';
    } else {
      if (savedKey) {
        console.log(
          'Your stored key is invalid. Proceeding with the login flow...'
        );
      }
      return 'PROCEED';
    }
  }
}

async function startLoginFlow() {
  console.log('\nWelcome to BundlePush!\n');
  console.log(
    '1) If you do not have an API key, we can open the BundlePush dashboard to generate one.'
  );
  console.log(
    '2) If you already have one, just skip opening the dashboard and paste it.\n'
  );

  const { openPortal } = await inquirer.prompt([
    {
      type: 'confirm',
      name: 'openPortal',
      message: 'Open the portal in your browser to generate an API key?',
      default: true,
    },
  ]);

  if (openPortal) {
    console.log('Opening browser...');
    await open(API_KEYS_URL);
  }

  let keyData = null;
  let apiKey = null;

  do {
    const promptResult = await inquirer.prompt([
      {
        type: 'input',
        name: 'apiKey',
        message: 'Paste your API key here:',
      },
    ]);

    apiKey = promptResult.apiKey;
    keyData = await fetchKeyData(apiKey);

    if (!keyData) {
      console.log('Invalid API key. Please try again.');
    }
  } while (!keyData);

  console.log(`✓ You are authenticated in ${keyData.organization.name}.`);
  await saveKeyToHome(apiKey);
}
