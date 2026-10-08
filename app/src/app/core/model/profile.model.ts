export type DiscordProfileInfo = {
  connected: boolean;
  username: string;
  commitNotifEnabled: boolean;
  weeklyNotifEnabled: boolean;
};

export type Profile = {
  id: string;
  username: string;
  discord: DiscordProfileInfo;
};

export type DiscordVerifyData = {
  code: string;
  botUsername: string;
  expiresAt: string;
  installUrl: string;
};

export type DiscordStatus = {
  verified: boolean;
  discordUsername: string;
};
