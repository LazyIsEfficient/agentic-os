export interface StreamConfig {
  hostname: string;
  port: number;
  username: string;
  password: string;
  vhost: string;
  streamName: string;
}

export function getStreamConfig(): StreamConfig {
  return {
    hostname: process.env.RABBITMQ_STREAM_HOST || "localhost",
    port: Number(process.env.RABBITMQ_STREAM_PORT || "5552"),
    username: process.env.RABBITMQ_USER || "guest",
    password: process.env.RABBITMQ_PASS || "guest",
    vhost: process.env.RABBITMQ_VHOST || "/",
    streamName: process.env.RABBITMQ_STREAM_NAME || "notes",
  };
}
