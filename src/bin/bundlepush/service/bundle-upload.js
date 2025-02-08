import { getApi } from './axios.js';

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
