#!/usr/bin/env node

import { Command } from 'commander';
import { handleAuthLogin } from './login/index.js';
import { handleRelease } from './release/index.js';

const program = new Command();

program
  .name('bundlepush')
  .description('Deploy React Native with OTA')
  .version('0.1.0');

const loginCommand = new Command('login')
  .description('Login using an API key')
  .action(handleAuthLogin);

const appsCommand = new Command('apps').description('Organization apps');

const listAppsCommand = new Command('list')
  .description('List organization apps')
  .action(() => console.log('apps list')); // TODO

appsCommand.addCommand(listAppsCommand);

const releaseCommand = new Command('release')
  .description('Release a new bundle of the app')
  .option('-a, --app <app>', 'App identifier')
  .action(handleRelease);

program.addCommand(loginCommand);
program.addCommand(appsCommand);
program.addCommand(releaseCommand);

program.parse(process.argv);
