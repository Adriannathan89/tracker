import { Injectable } from "@angular/core";
import axiosInstance from "../../lib/axios";

@Injectable({ providedIn: 'root' })
export class UserAuthService {
  async login(username: string, password: string) {
    await axiosInstance.post('/auth/login', { username, password });
    return true;
  }

  async logout() {
    await axiosInstance.post('/auth/logout');
  }

  async isAuthenticated() {
    try {
      const res = await axiosInstance.get('/auth/validate-session');
      if (res.status === 200) {
        return true;
      } else {
        return false;
      }
    } catch {
      return false;
    }
  }
}