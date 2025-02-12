import axios from 'axios';
import { BASE_URL } from '../config/variables.js';

export const getApi = () => {
  const client = axios.create({
    baseURL: BASE_URL,
    timeout: 60000,
  });

  return client;
};
