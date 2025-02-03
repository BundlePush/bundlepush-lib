import { keyCheckRequest } from '../service/keys-request.js';

export async function fetchKeyData(key) {
  try {
    const response = await keyCheckRequest(key);
    if (response.status >= 200 && response.status < 300 && response.data) {
      return response.data;
    }
    return null;
  } catch (error) {
    // console.error(error);
    return null;
  }
}
