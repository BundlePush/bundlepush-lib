import { keyCheckRequest } from '../service/keys-management.js';

export async function fetchKeyData(key) {
  try {
    const response = await keyCheckRequest(key);
    if (response.status >= 200 && response.status < 300 && response.data) {
      return response.data;
    }
    return null;
  } catch (error) {
    if (error?.status === 401) {
      console.log('Invalid or expired key.');
      return null;
    } else if (!error?.status) {
      console.log('Could not connect with BundlePush server.');
      process.exit(1);
    } else {
      console.log('An error occurred while fetching key data.');
      process.exit(1);
    }
  }
}
