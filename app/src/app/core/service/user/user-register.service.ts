import { Injectable } from "@angular/core";
import axiosInstance from "../../lib/axios";

export type RegisterRequest = {
  username: string;
  password: string;
};

@Injectable({ providedIn: 'root' })
export class UserRegisterService {
  async register(username: string, password: string) {
    await axiosInstance.post('/user/register', { username, password });
    return true;
  }
}