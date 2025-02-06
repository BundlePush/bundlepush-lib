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

// returns:
// {
//   "uploadFileId": "...",
//   "url": "..."
// }
export const requestUploadUrl = async ({ key, appId }) => {
  const response = await getApi().post(
    '/bundle/request-upload-url',
    {
      appId,
    },
    {
      headers: {
        'x-api-key': key,
        'Content-Type': 'application/json',
      },
    }
  );
  return response.data;
};
