import { getApi } from './axios.js';

// returns:
//   id: string;
//   name: string;
//   platform: 'ANDROID' | 'IOS';
export const getAppData = async ({ key, appId }) => {
  const response = await getApi().get(`/app/${appId}`, {
    headers: {
      'x-api-key': key,
      'Content-Type': 'application/json',
    },
  });
  return response.data;
};
