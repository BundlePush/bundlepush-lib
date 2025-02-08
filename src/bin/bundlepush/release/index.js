import { uploadFile } from '../service/aws.js';
import { createBundle, requestUploadUrl } from '../service/bundle.js';
import { getCurrentAuthState } from '../utils/getAuthState.js';
import md5File from 'md5-file';

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
  const uploadUrlData = await requestUploadUrl({
    key: result.key,
    appId: app,
  });

  // Step 3: upload the bundle
  await uploadFile({
    presignedUrl: uploadUrlData.url,
    localFile: 'package-lock.json', // TODO use correct file
  });

  const md5 = await md5File('package-lock.json');

  // Step 4: create the bundle
  await createBundle({
    key: result.key,
    appId: app,
    uploadFileId: uploadUrlData.uploadFileId,
    md5,
    // TODO add more options
  });
}
