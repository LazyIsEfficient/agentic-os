import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // The RabbitMQ stream client is a native-ish server dependency; keep it
  // external so Next does not try to bundle it into server components.
  serverExternalPackages: ["rabbitmq-stream-js-client"],
};

export default nextConfig;
