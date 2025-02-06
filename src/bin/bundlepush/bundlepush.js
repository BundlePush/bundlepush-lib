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

const releaseCommand = new Command('release')
  .description('Release a new bundle of the app')
  .action(handleRelease);

program.addCommand(loginCommand);
program.addCommand(releaseCommand);

program.parse(process.argv);
