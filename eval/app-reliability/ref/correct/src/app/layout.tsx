import type { ReactNode } from "react"

export const metadata = {
  title: "Notes (fault-tolerant)",
  description: "Durable-stream notes reference app",
}

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body
        style={{
          fontFamily: "system-ui, sans-serif",
          maxWidth: 640,
          margin: "2rem auto",
          padding: "0 1rem",
          lineHeight: 1.5,
        }}
      >
        {children}
      </body>
    </html>
  )
}
