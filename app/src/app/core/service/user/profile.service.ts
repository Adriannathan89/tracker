import { Injectable } from "@angular/core";
import axiosInstance from "../../lib/axios";
import { Profile, DiscordVerifyData, DiscordStatus } from "../../model/profile.model";

@Injectable({ providedIn: 'root' })
export class ProfileService {
  async getProfile(): Promise<Profile> {
    const res = await axiosInstance.get('/user/profile');
    return res.data.data;
  }

  async updateProfile(username: string): Promise<void> {
    await axiosInstance.put('/user/profile', { username });
  }

  async generateDiscordCode(): Promise<DiscordVerifyData> {
    const res = await axiosInstance.post('/user/discord/verify');
    return res.data.data;
  }

  async getDiscordStatus(): Promise<DiscordStatus> {
    const res = await axiosInstance.get('/user/discord/status');
    return res.data.data;
  }

  async disconnectDiscord(): Promise<void> {
    await axiosInstance.delete('/user/discord');
  }

  async updateNotifSettings(type: 'commit' | 'weekly', enabled: boolean): Promise<void> {
    await axiosInstance.put('/user/discord/notification', { type, enabled });
  }
}
