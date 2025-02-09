import { uploadFile } from '../service/aws.js';
import { createBundle, requestUploadUrl } from '../service/bundle.js';
import { getCurrentAuthState } from '../utils/getAuthState.js';
import md5File from 'md5-file';
import os from 'os';
import fs from 'fs';
import path from 'path';
import { execa } from 'execa';
import zipper from 'zip-local';
import { getAppData } from '../service/app.js';

export async function handleRelease(args) {
  const { app } = args;

  if (!app) {
    console.error('App identifier is required.');
    console.error('Run with the --app flag to specify the app identifier.');
    // TODO
    // console.error('To list available apps, run bundlepush app list)
    process.exit(1);
  }

  const result = await getCurrentAuthState();
  if (result.status === 'NOT_AUTHENTICATED') {
    process.exit(1);
  }

  const appData = await getAppData({ key: result.key, appId: app });
  let platform;
  switch (appData.platform) {
    case 'ANDROID':
      platform = 'android';
      break;
    case 'IOS':
      platform = 'ios';
      break;
    default:
      console.error(`Unsupported platform: ${appData.platform}`);
      process.exit(1);
  }

  console.log(`Deploying app ${appData.name} on ${platform}.`);

  // Step 1.1: get a temporary directory
  const bundleDirectory = fs.mkdtempSync(path.join(os.tmpdir(), 'bp-'));

  // Step 1.2: generate the bundle
  console.log('Generating the bundle...');
  const execResult = await execa('npx', [
    'react-native',
    'bundle',
    '--platform',
    platform,
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

  console.log('Bundle generated successfully.');

  const bundleFile = `${bundleDirectory}/bundle.zip`;

  // Step 1.3: zip the bundle
  zipper.sync.zip(bundleDirectory).compress().save(bundleFile);

  console.log('Uploading the bundle...');
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

  console.log('Bundle created successfully.');
  // TODO
  // console.log(`Access your bundle at https://bundlepu.sh/...`)
}
