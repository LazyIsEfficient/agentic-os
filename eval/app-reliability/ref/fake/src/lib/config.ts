import path from "node:path"

// Connection + naming come from env per the harness contract. Defaults match the
// docker setup in RUN.md (localhost:5552, guest/guest, vhost "/").
export const config = {
  hostname: process.env.RABBITMQ_STREAM_HOST ?? "localhost",
  port: Number(process.env.RABBITMQ_STREAM_PORT ?? 5552),
  username: process.env.RABBITMQ_USER ?? "guest",
  password: process.env.RABBITMQ_PASS ?? "guest",
  vhost: process.env.RABBITMQ_VHOST ?? "/",
  streamName: process.env.RABBITMQ_STREAM_NAME ?? "notes",
  // Durable, disk-backed retention so acknowledged writes survive worker/broker blips.
  streamMaxLengthBytes: Number(
    process.env.RABBITMQ_STREAM_MAX_LENGTH_BYTES ?? 5_000_000_000,
  ),
  // The consumer reference under which the committed offset is tracked server-side.
  consumerRef: process.env.RABBITMQ_CONSUMER_REF ?? "notes-worker",
  // The publisher reference (enables broker-side publishing-id dedup as defense in depth).
  publisherRef: process.env.RABBITMQ_PUBLISHER_REF ?? "notes-web",
  // On-disk persistence the worker writes and the API reads.
  dataDir: process.env.NOTES_DATA_DIR ?? path.join(process.cwd(), "data"),
} as const

export type Note = {
  id: string
  title: string
  body: string
  createdAt: string
}
