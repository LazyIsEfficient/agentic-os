// Shared connection + naming configuration, sourced entirely from env with
// the defaults the harness contract specifies.

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
    hostname: process.env.RABBITMQ_STREAM_HOST ?? "localhost",
    port: Number(process.env.RABBITMQ_STREAM_PORT ?? "5552"),
    username: process.env.RABBITMQ_USER ?? "guest",
    password: process.env.RABBITMQ_PASS ?? "guest",
    vhost: process.env.RABBITMQ_VHOST ?? "/",
    streamName: process.env.RABBITMQ_STREAM_NAME ?? "notes",
  };
}

// Stable reference used both for publisher-side broker dedup and for the
// consumer's server-side offset tracking. Keeping it constant is what lets a
// restarted worker resume from its last committed offset.
export const CONSUMER_REF = "notes-worker";
export const PUBLISHER_REF = "notes-publisher";

export interface Note {
  id: string;
  title: string;
  body: string;
  createdAt: string;
}
