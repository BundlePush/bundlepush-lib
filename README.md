# BundlePush Documentation

Lightning-Fast App Deployment.

BundlePush streamlines and accelerates React Native CLI app deployment with Over-the-Air (OTA) strategy.

BundlePush is an alternative to Microsoft CodePush and Expo EAS.

## Requirements

- **React Native CLI** (Expo is not supported)
- **React Native >= 0.72**  
  (older versions are not verified)
- **iOS >= 12.4**
- **Android**  
  Currently not supported; coming soon!

## Over-the-air updates

Over-the-Air (OTA) updates involve some complexity, but they offer significant advantages for React Native apps:

- They allow you to deploy bug fixes and new features without going through app store review processes
- Users receive updates faster, improving their experience
- You can rollback problematic updates quickly if issues arise

For those new to OTA updates, we recommend reading [this excellent article](https://dev.to/ponikar/ota-updates-in-react-native-1pbo) to understand the underlying concepts.

**Important:** Always thoroughly test your updates in a development environment before deploying to production users.

## Let's code

### Step 1 - Account

Visit [BundlePush Dashboard](https://dash.bundlepu.sh), create an account, and set up your first app.

### Step 2 - Add the library

1. **Install the BundlePush library** using either command below:

   ```bash
   npm install bundlepush
   ```

   or

   ```bash
   yarn add bundlepush
   ```

   After installing the library, install the iOS dependencies:

   ```bash
   cd ios
   pod install
   cd ..
   ```

2. **Add the native code** to iOS:

- If you're using Objective-C (`AppDelegate.mm`), follow the documentation in [Objective-C integration guide](docs/objective-c.md)
- If you're using Swift (`AppDelegate.swift`), follow the documentation in [Swift integration guide](docs/swift.md)
- **Android support** is not available yet, but will be coming soon.

4. **Compile and run** your app to confirm that everything is configured correctly.

## Test

You can follow the steps below to test your app with BundlePush:

1. Edit your app code as desired, then open a terminal.
2. `cd` to your project's root directory.
3. Login to BundlePush and follow the steps:
   ```bash
   npx bundlepush login
   ```
4. Once logged in, deploy a version with:
   ```bash
   npx bundlepush release --app <YOUR_APP_ID>
   ```
5. After the app is deployed, open the [BundlePush Dashboard](https://dash.bundlepu.sh).
6. In the dashboard, navigate to the current bundle:
   - Add the version and build number of your app in the Versions section.
   - Enable **"Dev Mode"**.
7. Build the app in debug mode. Wait a few seconds for the bundle to download in the background.
8. Restart the app. The newly deployed bundle should be installed and running.

## Deploy in production

Deployments to production are not available in debug builds. Ensure you are using a production (release) build of your app. In the [BundlePush Dashboard](https://dash.bundlepu.sh):

1. Select the bundle you want to release.
2. Specify all app versions (and build numbers) that the bundle should be available for.
3. Enable the bundle so it becomes active for matching app sessions.
4. If you want to test the bundle immediately, install and launch the production build.
5. If you discover an issue, disable the bundle right away to revert back to a safe state.

## Troubleshoot

If you are not seeing the updated bundle, please verify the following:

1. **Native Configuration**: Ensure that BundlePush is correctly installed and configured in your app's native code.
2. **App ID Match**: Double-check that the app ID you used to release the bundle matches the app ID in your code.
3. **Version and Build Number**: Confirm that the version and build number you set in the dashboard match the installed app's version and build number.
4. **Bundle Availability**: Make sure that the bundle is in **Dev Mode** if you are testing in debug, or is **enabled** if you are running in production.

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

[BSL](LICENSE-BSL)

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
