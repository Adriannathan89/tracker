import axios, { type InternalAxiosRequestConfig } from 'axios';
import { trackerEnv } from '../../../environments/environment.generated';

const axiosInstance = axios.create({
  baseURL: trackerEnv.TRACKER_API_BASE_URL,
  withCredentials: true,
  headers: {
    'Content-Type': 'application/json'
  }
});

let refresh: Promise<void> | undefined;

axiosInstance.interceptors.response.use(
  (response) => response,
  async (error) => {
    const config = error.config as (InternalAxiosRequestConfig & { trackerRetried?: boolean }) | undefined;
    const authRequest = ['/auth/login', '/auth/logout', '/auth/refresh', '/user/register']
      .includes(config?.url ?? '');
    if (error.response?.status !== 401 || !config || authRequest) throw error;
    if (config.trackerRetried) {
      window.location.href = '/login';
      throw error;
    }
    config.trackerRetried = true;
    refresh ??= axiosInstance.post('/auth/refresh').then(() => undefined)
      .finally(() => { refresh = undefined; });
    try {
      await refresh;
    } catch {
      window.location.href = '/login';
      throw error;
    }
    return axiosInstance.request(config);
  }
);

export default axiosInstance;
