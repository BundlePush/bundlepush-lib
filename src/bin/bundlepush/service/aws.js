import axios from 'axios';
import fs from 'fs';

export const uploadFile = async ({ presignedUrl, localFile }) => {
  const { size } = fs.statSync(localFile);
  const fileStream = fs.createReadStream(localFile);
  const response = await axios.put(presignedUrl, fileStream, {
    headers: {
      'Content-Type': 'application/zip',
      'Content-Length': size,
    },
    maxContentLength: Infinity,
    maxBodyLength: Infinity,
  });

  return response.data;
};
