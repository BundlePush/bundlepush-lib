import { BUNDLEPUSH_API_KEY } from '../config/variables.js';
import { loadKeyFromHome } from '../utils/keysInHome.js';
import { fetchKeyData } from '../utils/fetchKeyData.js';

export async function getCurrentAuthState({
  notAuthenticatedMessage = 'You are not authenticated.\nRun `bundlepush login`.',
}) {
  // 1. Check if an ENV variable key exists
  if (BUNDLEPUSH_API_KEY) {
    const keyData = await fetchKeyData(BUNDLEPUSH_API_KEY);
    if (keyData) {
      console.log(`✓ You are authenticated in ${keyData.organization.name}.`);
      return {
        status: 'AUTHENTICATED',
        keyData,
      };
    } else {
      console.log('The provided key in environment variable is invalid.');
      process.exit(1);
    }
  } else {
    // 2. If no ENV key, check if we have a saved key in the home directory
    const savedKey = await loadKeyFromHome();
    const keyData = savedKey ? await fetchKeyData(savedKey) : null;
    if (keyData) {
      console.log(
        `✓ You are already authenticated in ${keyData.organization.name}.`
      );
      return {
        status: 'AUTHENTICATED',
        keyData,
      };
    } else {
      if (savedKey) {
        console.log(notAuthenticatedMessage);
      }
      return {
        status: 'NOT_AUTHENTICATED',
      };
    }
  }
}
