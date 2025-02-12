import { getApi } from './axios.js';

// returns:
// {
//   "organization": {
//     "name": "Cernov Apps",
//     "id": "1234567890"
//   }
// }
export const keyCheckRequest = (key) =>
  getApi().get('/keys/check', {
    headers: {
      'x-api-key': key,
    },
  });
