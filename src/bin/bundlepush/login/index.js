import inquirer from 'inquirer';
import open from 'open';
import { API_KEYS_URL } from '../config/variables.js';
import { saveKeyToHome } from '../utils/keysInHome.js';
import { fetchKeyData } from '../utils/fetchKeyData.js';
import { getCurrentAuthState } from '../utils/getAuthState.js';

export async function handleAuthLogin() {
  const result = await getCurrentAuthState({
    notAuthenticatedMessage: 'Proceeding with the login flow...',
  });

  if (result.status === 'AUTHENTICATED') {
    return;
  } else if (result.status === 'NOT_AUTHENTICATED') {
    await startLoginFlow();
  }
  // unexpected
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
