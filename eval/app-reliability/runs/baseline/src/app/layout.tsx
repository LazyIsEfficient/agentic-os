import type { ReactNode } from "react";

export const metadata = {
  title: "Notes",
  description: "Fault-tolerant note-taking app backed by a RabbitMQ stream",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
