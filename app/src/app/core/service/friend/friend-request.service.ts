import { Injectable } from "@angular/core";
import axiosInstance from "../../lib/axios";

export type FriendRequest = {
  id: string;
  senderUsername: string;
  receiverUsername: string;
}

@Injectable({ providedIn: 'root' })
export class FriendRequestService {
  async getFriendsRequest() {
    const res = await axiosInstance.get('/user/friend/request');
    if (res.data.data === null) return [];
    return res.data.data.map((request: any) => ({
      id: request.id,
      senderUsername: request.sender.username,
      receiverUsername: request.receiver.username
    })) as FriendRequest[];
  }

  async sendFriendRequest(friendId: string) {
    await axiosInstance.post('/user/friend/add', { friendId });
    return true;
  }

  async responseFriendRequest(friendRequestId: string, action: 'accept' | 'reject') {
    await axiosInstance.put('/user/friend/request/response', { friendRequestId, action });
    return true;
  }
}