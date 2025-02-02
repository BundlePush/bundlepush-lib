#!/usr/bin/env node

import { Command } from 'commander';
import { handleAuthLogin } from './auth/login/index.js';

const program = new Command();

program
  .name('bundlepush')
  .description('Deploy React Native with OTA')
  .version('0.1.0');

const authCommand = new Command('auth').description('Authentication');

const loginCommand = new Command('login')
  .description('Login using an API key')
  .action(handleAuthLogin);
authCommand.addCommand(loginCommand);

program.addCommand(authCommand);

program.parse(process.argv);
