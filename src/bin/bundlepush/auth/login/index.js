// const inquirer = require('inquirer');
// const open = require('open');

async function handleAuthLogin() {
  const result = await checkCurrentAuthState();

  if (result === 'FINISH') {
    return;
  }

  if (result === 'PROCEED') {
    await startLoginFlow();
  }

  throw new Error('Invalid auth state');
}

async function checkCurrentAuthState() {
  // 1. Check if an ENV variable key exists
  // TODO move env to other shared file
  const envKey = process.env.BUNDLEPUSH_API_KEY;
  if (envKey) {
    const valid = await isKeyValid(envKey);
    if (valid) {
      console.log(
        '✓ You are already authenticated with a valid BUNDLEPUSH_API_KEY.'
      );
      return 'FINISH';
    } else {
      console.log(
        'BP_API_KEY is set but invalid. Proceeding with the login flow...'
      );
      return 'PROCEED';
    }
  } else {
    // 2. If no ENV key, check if we have a saved key in the home directory
    const savedKey = loadKeyFromHome();
    if (savedKey && (await isKeyValid(savedKey))) {
      console.log(
        '✓ You are already authenticated (key found in your home directory).'
      );
      return 'FINISH';
    } else {
      console.log(
        'Your stored key is invalid. Proceeding with the login flow...'
      );
      return 'PROCEED';
    }
  }
}

async function startLoginFlow() {
  console.log('\nNo valid API key found.');
  console.log(
    '1) If you do not have an API key, we can open the BundlePush dashboard to generate one.'
  );
  console.log(
    '2) If you already have one, just skip opening the dashboard and paste it.\n'
  );

  // const { openPortal } = await inquirer.prompt([
  //   {
  //     type: 'confirm',
  //     name: 'openPortal',
  //     message: 'Open the portal in your browser to generate an API key?',
  //     default: true,
  //   },
  // ]);

  // if (openPortal) {
  //  console.log('Opening browser...');
  //  await open('https://bundlepu.sh'); // TODO
  // }
}

module.exports = {
  handleAuthLogin,
};

// TODO implement and move to other files
function isKeyValid(key) {
  // TODO
  return key === 'VALID';
}

function loadKeyFromHome() {
  // TODO
  return 'VALID';
}
