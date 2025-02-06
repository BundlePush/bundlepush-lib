import { uploadFile } from '../service/aws.js';
import { requestUploadUrl } from '../service/keys-request.js';
import { getCurrentAuthState } from '../utils/getAuthState.js';

export async function handleRelease(args) {
  const { app } = args;

  if (!app) {
    console.error('App identifier is required.');
    process.exit(1);
  }

  const result = await getCurrentAuthState();
  if (result.status === 'NOT_AUTHENTICATED') {
    process.exit(1);
  }

  // TODO check if app is from organization

  // TODO Step 1: build the app

  // Step 2: request upload key
  console.log('result.key', result.key);
  const uploadUrlData = await requestUploadUrl({
    key: result.key,
    appId: app,
  });

  // Step 3: upload the bundle
  await uploadFile({
    presignedUrl: uploadUrlData.url,
    localFile: 'package-lock.json', // TODO use correct file
  });

  // TODO Step 4: confirm the upload with app data
}
