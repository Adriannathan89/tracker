import { Injectable } from "@angular/core";
import axiosInstance from "../../lib/axios";

export type Friend = {
  id: string;
  username: string;
  status: string;
}

@Injectable({ providedIn: "root" })
export class FriendService {
  async getFriend() {
    const res = await axiosInstance.get('/user/friend');
    if (res.data.data === null) return [];
    return res.data.data.map((friend: any) => ({
      id: friend.id,
      username: friend.username,
      status: friend.status
    })) as Friend[];
  }

  async searchFriend(keyword: string) {
    const res = await axiosInstance.post('/user/friend/search', { name: keyword });
    if (res.data.data === null) return [];
    return res.data.data.map((friend: any) => ({
      id: friend.id,
      username: friend.username,
      status: friend.status
    })) as Friend[];
  }
}