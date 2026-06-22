/** @type {import('next').NextConfig} */
const nextConfig = {
  // The stream client is a server-only dep; keep it out of the bundle so its
  // Node socket internals aren't traced/bundled into server components.
  experimental: {
    serverComponentsExternalPackages: ["rabbitmq-stream-js-client"],
  },
};
export default nextConfig;
