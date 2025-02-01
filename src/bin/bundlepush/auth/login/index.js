async function handleAuthLogin() {
  // 1. Check if an ENV variable key exists
  // TODO move env to other shared file
  const envKey = process.env.BUNDLEPUSH_API_KEY;
  if (envKey) {
    const valid = await isKeyValid(envKey);
    if (valid) {
      console.log(
        '✓ You are already authenticated with a valid BUNDLEPUSH_API_KEY.'
      );
      return;
    } else {
      console.log(
        'BP_API_KEY is set but invalid. Proceeding with the login flow...'
      );
    }
  } else {
    // 2. If no ENV key, check if we have a saved key in the home directory
    const savedKey = loadKeyFromHome();
    if (savedKey && (await isKeyValid(savedKey))) {
      console.log(
        '✓ You are already authenticated (key found in your home directory).'
      );
      return;
    } else {
      console.log(
        'Your stored key is invalid. Proceeding with the login flow...'
      );
      return;
    }
  }
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
