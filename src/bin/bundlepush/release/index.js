import { uploadFile } from '../service/aws.js';
import { createBundle, requestUploadUrl } from '../service/bundle.js';
import { getCurrentAuthState } from '../utils/getAuthState.js';
import md5File from 'md5-file';
import os from 'os';
import fs from 'fs';
import path from 'path';
import { execa } from 'execa';
import zipper from 'zip-local';

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
  // TODO retrieve app's platform

  // Step 1.1: get a temporary directory
  const bundleDirectory = fs.mkdtempSync(path.join(os.tmpdir(), 'bp-'));

  // Step 1.2: generate the bundle
  const execResult = await execa('npx', [
    'react-native',
    'bundle',
    '--platform',
    'ios',
    '--dev',
    'false',
    '--entry-file',
    'index.js',
    '--bundle-output',
    `${bundleDirectory}/main.jsbundle`,
    '--assets-dest',
    bundleDirectory,
  ]);
  if (execResult.exitCode !== 0) {
    console.error('Failed to generate the bundle');
    console.error(execResult.stderr);
    process.exit(1);
  }

  const bundleFile = `${bundleDirectory}/bundle.zip`;

  // Step 1.3: zip the bundle
  zipper.sync.zip(bundleDirectory).compress().save(bundleFile);

  // Step 2: request upload key
  const uploadUrlData = await requestUploadUrl({
    key: result.key,
    appId: app,
  });

  // Step 3: upload the bundle
  await uploadFile({
    presignedUrl: uploadUrlData.url,
    localFile: bundleFile,
  });

  const md5 = await md5File(bundleFile);

  // Step 4: create the bundle
  await createBundle({
    key: result.key,
    appId: app,
    uploadFileId: uploadUrlData.uploadFileId,
    md5,
    // TODO add more options
  });
}
