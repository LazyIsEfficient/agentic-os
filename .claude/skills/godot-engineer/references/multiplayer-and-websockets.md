# Multiplayer and WebSockets

This file is specifically about **WebSocket-based multiplayer in Godot 4 with C#** — the right pattern for browser-friendly games, asymmetric network conditions, and games that need to traverse firewalls without UDP.

WebSockets are the right choice when:

- The game runs on the **web** (where UDP isn't available).
- You need **firewall traversal** without NAT punching or relays.
- You need a **simple deployment model** (HTTP-style infrastructure, TLS, load balancers).
- The game is **turn-based or low-tempo** enough that TCP latency is acceptable.

WebSockets are *not* the right choice when:

- You need **sub-50ms responsiveness** for fast-paced action (use ENet or UDP).
- You need **lockstep determinism** for fighting games (use a deterministic protocol).
- You're shipping **only to native platforms** with no web target (UDP is faster).

For this skill, the assumption is **WebSockets are the chosen transport**. Godot 4 has first-class support via `WebSocketMultiplayerPeer`.

## Godot's High-Level Multiplayer

Godot's "high-level multiplayer" API is the layer that lets you call methods on remote peers (RPCs) and synchronize state across the network. It's transport-agnostic — the same RPC code works over ENet, WebSockets, or WebRTC. You pick the transport via the `MultiplayerPeer` you assign.

The architecture:

1. **A `MultiplayerPeer`** handles the actual network connection. For WebSockets, this is `WebSocketMultiplayerPeer`.
2. **The `MultiplayerAPI`** (one per `SceneTree`) manages the high-level RPC system on top of the peer.
3. **Nodes call RPCs** on each other; the API serializes the calls and sends them over the peer.
4. **Authority** determines which peer "owns" a node and is the source of truth for it.

## Basic Setup

### Server

```csharp
public partial class Server : Node
{
    [Export] public int Port { get; set; } = 9000;

    public void Start()
    {
        var peer = new WebSocketMultiplayerPeer();
        var error = peer.CreateServer(Port);
        if (error != Error.Ok)
        {
            GD.PrintErr($"Failed to start server: {error}");
            return;
        }

        Multiplayer.MultiplayerPeer = peer;
        GD.Print($"Server started on port {Port}");

        Multiplayer.PeerConnected += OnPeerConnected;
        Multiplayer.PeerDisconnected += OnPeerDisconnected;
    }

    private void OnPeerConnected(long id)
    {
        GD.Print($"Peer {id} connected");
        // Spawn a player for this peer, etc.
    }

    private void OnPeerDisconnected(long id)
    {
        GD.Print($"Peer {id} disconnected");
        // Clean up that peer's state
    }
}
```

### Client

```csharp
public partial class Client : Node
{
    [Export] public string ServerUrl { get; set; } = "ws://localhost:9000";

    public void Connect()
    {
        var peer = new WebSocketMultiplayerPeer();
        var error = peer.CreateClient(ServerUrl);
        if (error != Error.Ok)
        {
            GD.PrintErr($"Failed to create client: {error}");
            return;
        }

        Multiplayer.MultiplayerPeer = peer;

        Multiplayer.ConnectedToServer += OnConnectedToServer;
        Multiplayer.ConnectionFailed += OnConnectionFailed;
        Multiplayer.ServerDisconnected += OnServerDisconnected;
    }

    private void OnConnectedToServer()
    {
        GD.Print("Connected to server");
    }

    private void OnConnectionFailed()
    {
        GD.PrintErr("Connection failed");
    }

    private void OnServerDisconnected()
    {
        GD.Print("Disconnected from server");
    }
}
```

A few things to note:

- **`ws://`** for unencrypted WebSocket; **`wss://`** for TLS-encrypted (use this in production).
- **`CreateServer(port)`** for the server; **`CreateClient(url)`** for the client.
- **The same `MultiplayerPeer` interface** works for both; the difference is whether you call `CreateServer` or `CreateClient`.
- **`Multiplayer.PeerConnected` / `PeerDisconnected`** fire on the *server*; on the client, you only see your own connection state.

## RPCs

A Remote Procedure Call (RPC) is a method that, when called on one peer, executes on another peer (or many peers). In Godot 4 C#:

```csharp
public partial class Player : CharacterBody2D
{
    [Rpc(MultiplayerApi.RpcMode.Authority, CallLocal = true, TransferMode = MultiplayerPeer.TransferModeEnum.Reliable)]
    public void SpawnAt(Vector2 position)
    {
        GlobalPosition = position;
        Visible = true;
    }

    [Rpc(MultiplayerApi.RpcMode.AnyPeer, TransferMode = MultiplayerPeer.TransferModeEnum.Unreliable)]
    public void RequestMove(Vector2 newPosition)
    {
        // Validate on the server
        if (Multiplayer.IsServer())
        {
            // Sanity-check the move
            if (newPosition.DistanceTo(GlobalPosition) > MaxMoveDistance) return;
            GlobalPosition = newPosition;
            // Broadcast the new position to all clients
            Rpc(MethodName.SyncPosition, newPosition);
        }
    }

    [Rpc(MultiplayerApi.RpcMode.Authority, CallLocal = false, TransferMode = MultiplayerPeer.TransferModeEnum.Reliable)]
    public void SyncPosition(Vector2 newPosition)
    {
        GlobalPosition = newPosition;
    }
}
```

The `[Rpc]` attribute marks a method as RPC-callable. The parameters:

- **`RpcMode`**:
  - **`Authority`**: only the peer with authority over this node can call it.
  - **`AnyPeer`**: any peer can call it.
- **`CallLocal`**: whether the local peer also runs the method when calling RPC. Default is `false` (only remote runs).
- **`TransferMode`**:
  - **`Reliable`**: guaranteed delivery, in order. Slower. Use for important events.
  - **`Unreliable`**: fire and forget. Fastest. Use for high-frequency state updates where missing one is fine.
  - **`UnreliableOrdered`**: fire and forget but ordered. Use for sequenced state updates.

To call an RPC:

```csharp
// Call RPC on this node, on all peers (including server)
Rpc(MethodName.SpawnAt, new Vector2(100, 100));

// Call RPC on this node, on a specific peer
RpcId(targetPeerId, MethodName.SpawnAt, new Vector2(100, 100));

// Call RPC on this node, locally only (just calls the method)
SpawnAt(new Vector2(100, 100));
```

The `MethodName.SpawnAt` is a generated constant (similar to `SignalName.X`). Use it for type safety.

**Important caveat for WebSockets**: WebSockets are TCP-based, so "Unreliable" RPCs are still delivered reliably and in order. The `TransferMode` is *advisory* — the WebSocket peer ignores it and treats everything as reliable. This is different from ENet, where unreliable is genuinely faster. For WebSocket-based games, design assuming all messages are reliable.

## Authority

Each node has an **authority** — a peer ID that's the source of truth for that node. By default, the server (peer ID 1) has authority over everything.

```csharp
// Set authority on a node
playerNode.SetMultiplayerAuthority(peerId);

// Check authority
if (playerNode.IsMultiplayerAuthority()) { ... }

// Get the authority's peer ID
var authority = playerNode.GetMultiplayerAuthority();
```

The authority pattern is critical for security: only the authoritative peer should make decisions about its node's state. Other peers see *the result* of those decisions but don't get to modify them.

For most networked games, **the server is the authority**. Clients send inputs (move requests, action requests); the server validates them, applies them, and broadcasts the results. This prevents cheating because clients can't directly modify game state — they can only ask the server to do things.

The opposite pattern (**clients have authority over their own players**) is simpler but vulnerable to cheating. It's fine for cooperative or trusted games; it's wrong for competitive games.

## State Synchronization

For state that changes frequently (player positions, animations, health), you have several options:

### Manual sync (RPC every frame)

The simplest approach: send the state via RPC every physics frame.

```csharp
public override void _PhysicsProcess(double delta)
{
    if (IsMultiplayerAuthority())
    {
        // Local player; do movement and broadcast
        DoMovement(delta);
        Rpc(MethodName.SyncTransform, GlobalPosition, Rotation);
    }
}

[Rpc(MultiplayerApi.RpcMode.Authority, CallLocal = false, TransferMode = MultiplayerPeer.TransferModeEnum.Reliable)]
public void SyncTransform(Vector2 position, float rotation)
{
    GlobalPosition = position;
    Rotation = rotation;
}
```

This works for small games but doesn't scale — every frame sends a packet per player. For 60 FPS and 8 players, that's 480 packets per second. Over WebSockets, this can saturate.

### `MultiplayerSynchronizer` node

Godot 4 has a `MultiplayerSynchronizer` node that automatically synchronizes specified properties of a node. Add it as a child of the node you want to sync; configure which properties to replicate; the engine handles the rest.

```
Player (CharacterBody2D)
├── Sprite2D
├── MultiplayerSynchronizer
│   Replication Config:
│     - position
│     - rotation
│     - velocity
└── ...
```

The `MultiplayerSynchronizer` reads the properties on the authority peer and replicates them to all other peers. By default, it sends every frame; you can configure the rate.

This is the recommended way to sync state in Godot 4. It's less code than manual RPCs and the engine optimizes the wire format.

### `MultiplayerSpawner` node

Similarly, `MultiplayerSpawner` automatically replicates node spawning across the network. Add it to a parent node, configure which scenes can be spawned, and when the authority spawns one, all clients receive the spawn.

```
Level
├── MultiplayerSpawner
│   Spawn Path: ../Players
│   Spawnable Scenes: [player.tscn, enemy.tscn]
└── Players (Node)
```

When the server adds a child to `Players`, the spawner replicates it. When the server removes it, all clients also remove it.

### Bandwidth considerations

WebSockets over TLS have a per-message overhead. Sending hundreds of small messages per second is wasteful. Two strategies:

- **Batch updates**: collect state changes for multiple objects and send them in one RPC.
- **Reduce update frequency**: sync at 20Hz instead of 60Hz; interpolate visually on the client.

```csharp
private float _syncTimer = 0;
private const float SyncInterval = 1.0f / 20.0f; // 20Hz

public override void _PhysicsProcess(double delta)
{
    if (IsMultiplayerAuthority())
    {
        DoMovement(delta);
        _syncTimer += (float)delta;
        if (_syncTimer >= SyncInterval)
        {
            Rpc(MethodName.SyncTransform, GlobalPosition, Rotation);
            _syncTimer = 0;
        }
    }
}
```

Then on the client side, interpolate visually between received positions:

```csharp
private Vector2 _lastReceivedPosition;
private Vector2 _targetPosition;
private float _interpolationTimer = 0;

public override void _Process(double delta)
{
    if (!IsMultiplayerAuthority())
    {
        // Interpolate toward the latest received position
        _interpolationTimer += (float)delta;
        var t = Mathf.Min(_interpolationTimer / SyncInterval, 1.0f);
        GlobalPosition = _lastReceivedPosition.Lerp(_targetPosition, t);
    }
}

[Rpc(MultiplayerApi.RpcMode.Authority, CallLocal = false, TransferMode = MultiplayerPeer.TransferModeEnum.Reliable)]
public void SyncTransform(Vector2 position, float rotation)
{
    _lastReceivedPosition = GlobalPosition;
    _targetPosition = position;
    _interpolationTimer = 0;
    Rotation = rotation;
}
```

20Hz updates with client-side interpolation often look as smooth as 60Hz updates with much less bandwidth.

## Client-Side Prediction (Briefly)

For competitive games where input latency matters, you want **client-side prediction**: the client immediately applies its own input locally, then reconciles with the server's authoritative state.

The pattern:

1. Client sends input to server.
2. Client immediately applies input locally (predicted).
3. Server processes input, sends back authoritative state.
4. Client compares its predicted state to the server's state.
5. If they differ, the client rolls back and re-applies inputs.

This is *complex*. Implementing it correctly is a significant undertaking. The high-level Godot API doesn't provide it; you build it on top.

For most WebSocket-based games, **don't bother with prediction**. WebSockets are usually slow enough that prediction isn't appropriate; if you need prediction-quality responsiveness, you probably shouldn't be using WebSockets in the first place.

If you really need prediction over WebSockets (e.g., a fast-paced game that must run on web), consider:

- **Predictive movement only**, not predictive combat.
- **Authoritative server for combat** to prevent cheating.
- **Visual interpolation everywhere** to hide the network roughness.

## Server vs Peer-to-Peer

Two architectures:

### Dedicated server

- One process is the server; all clients connect to it.
- The server has authority over all game state.
- Clients send inputs and receive state.
- **Pros**: cheat resistance; consistent experience; can be hosted in the cloud.
- **Cons**: requires server infrastructure; cost.

### Peer-to-peer with one host

- One client is the "host" and acts as the server. Other clients connect to it.
- The host has authority over all game state.
- **Pros**: no server infrastructure cost.
- **Cons**: host has an unfair advantage (zero latency to itself); host migration is hard; vulnerable to host's network conditions; firewall traversal is harder (though WebSockets help).

For WebSocket games, **dedicated server is the more practical choice**. WebSockets need a server endpoint anyway; making it a dedicated server is straightforward. P2P over WebSockets requires a relay server, which is basically just a dedicated server again.

## Hosting a Godot WebSocket Server

A Godot multiplayer server can run as:

1. **A regular Godot exported binary** in headless mode (`--headless`).
2. **A separate "server" project** that shares code with the client via a shared module.
3. **A custom server** in another language that speaks Godot's protocol (advanced).

The first option is the easiest. Build your client project with a "server" feature flag; export it as a Linux server build; deploy to a VPS or container.

```csharp
public override void _Ready()
{
    if (OS.HasFeature("dedicated_server") || "--server" in OS.GetCmdlineArgs())
    {
        StartServer();
    }
    else
    {
        ShowMainMenu();
    }
}
```

For deployment, treat the server like any other long-running process. See:

- **the `devops-engineer` agent** for provisioning the host
- **[deployment-pipelines](../../deployment-pipelines/SKILL.md)** for the build and deploy
- **site-reliability-engineering** for keeping it running and observing it

## TLS / Secure WebSockets

Production WebSocket servers should use TLS (`wss://`). Godot can handle TLS via either:

- **Godot's built-in TLS**: configure the server with a certificate.
- **A reverse proxy in front**: nginx, Caddy, or a load balancer terminates TLS and forwards plain WebSocket to Godot.

The reverse proxy approach is usually easier — let the proxy handle certificate renewal (Let's Encrypt), the Godot server stays simple.

```nginx
server {
    listen 443 ssl;
    server_name game.example.com;

    ssl_certificate /etc/letsencrypt/live/game.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/game.example.com/privkey.pem;

    location /game {
        proxy_pass http://localhost:9000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

The client connects with `wss://game.example.com/game`.

## Lobbies and Matchmaking

For more than a single fixed server, you need a lobby/matchmaking system. WebSockets work naturally with HTTP infrastructure, so the typical pattern:

1. **An HTTP API** (separate from the game server) handles authentication, lobby browsing, matchmaking.
2. **The HTTP API tells the client** which game server to connect to.
3. **The client connects to the chosen game server** via WebSocket.

The HTTP API can be:

- A custom backend (Node, Go, Python, .NET) — pair with the `engineer` agent, the `devops-engineer` agent, etc.
- A managed service (PlayFab, Nakama, Heroic Labs).
- The game server itself (one server handles both lobby and game; simpler but doesn't scale to many concurrent rooms).

## Security

Multiplayer games are a security concern. The basics:

### Server-side validation

The client cannot be trusted. Anything the client says about its own state should be validated by the server before being applied:

- **Move requests**: check the move is legal (distance, direction, collisions).
- **Action requests**: check the action is allowed (cooldowns, permissions).
- **State changes**: never let the client directly set game state; always go through validation.

A common pattern: clients send *intents* (what they want to do); the server decides whether to allow it.

```csharp
[Rpc(MultiplayerApi.RpcMode.AnyPeer)]
public void RequestAttack(int targetPlayerId)
{
    if (!Multiplayer.IsServer()) return;

    var sender = Multiplayer.GetRemoteSenderId();
    var attacker = GetPlayer(sender);
    var target = GetPlayer(targetPlayerId);

    // Validate
    if (attacker == null || target == null) return;
    if (attacker.Cooldown > 0) return;
    if (attacker.Position.DistanceTo(target.Position) > attacker.AttackRange) return;

    // Apply
    target.TakeDamage(attacker.AttackDamage);
    attacker.Cooldown = attacker.AttackCooldown;

    // Broadcast result
    Rpc(MethodName.OnAttack, sender, targetPlayerId, attacker.AttackDamage);
}
```

The server is the only authority on attack outcomes. Clients just play the visual result.

### Rate limiting

Clients can spam RPCs. The server should rate-limit per-client: max N RPCs per second per peer. Drop or disconnect peers that exceed.

### Authentication

If your game has user accounts, authenticate the WebSocket connection:

- Pass a token in the URL or as a header during the WebSocket handshake.
- Validate the token on the server before accepting the connection.
- Reject unauthenticated connections.

```csharp
// Client
peer.CreateClient($"wss://game.example.com/game?token={authToken}");

// Server (need to check the URL during handshake — Godot exposes this via the underlying HTTP request)
```

Godot's `WebSocketMultiplayerPeer` doesn't expose the handshake headers easily; for production auth, you may need to use a reverse proxy that validates the token before passing to the game server.

### Anti-cheat

Beyond server-side validation, common anti-cheat measures:

- **Track suspicious patterns**: a player whose actions are too fast or too consistent might be using a bot.
- **Rate-limit movement and actions** strictly.
- **Refuse client-side hit confirmation** (always validate hits server-side).
- **Encrypt sensitive game state** before sending to the client (so the client can't see things it shouldn't, like enemy positions outside vision).

For competitive games, cheating is a real concern; refer to [security-engineering](../../security-engineering/SKILL.md) for broader practices.

## Reconnection and Network Loss

Networks fail. Connections drop. Players reload tabs. The game has to handle this gracefully.

### Detecting disconnection

The `Multiplayer.ServerDisconnected` signal fires on the client when the server connection is lost. The `Multiplayer.PeerDisconnected` signal fires on the server when a peer disconnects.

```csharp
public override void _Ready()
{
    Multiplayer.ServerDisconnected += OnServerDisconnected;
}

private void OnServerDisconnected()
{
    GD.Print("Lost connection to server");
    ShowReconnectDialog();
}
```

### Reconnection strategy

For brief disconnects (network blip), automatically reconnect with backoff:

```csharp
private int _reconnectAttempts = 0;
private const int MaxReconnectAttempts = 5;

private async void TryReconnect()
{
    if (_reconnectAttempts >= MaxReconnectAttempts)
    {
        ShowReconnectFailed();
        return;
    }

    var backoff = Mathf.Pow(2, _reconnectAttempts) * 1000; // 1s, 2s, 4s, 8s, 16s
    await ToSignal(GetTree().CreateTimer(backoff / 1000.0), Timer.SignalName.Timeout);

    _reconnectAttempts++;
    Connect();
}
```

For session continuity, the server needs to remember the player's state for some time after they disconnect, and let them re-claim it on reconnect (often with a session token).

### Graceful failure

When reconnection fails, the game should:

- Show a clear error message ("Lost connection to server").
- Offer a way to retry or return to the main menu.
- Save any progress that can be saved locally.
- Not crash or hang.

## Anti-Patterns

- **Trusting the client.** Clients lie. Validate everything server-side.
- **Authority on the client** in a competitive game. Clients can cheat.
- **State changes via direct property set.** Use RPCs through the high-level API.
- **Sending large RPCs every frame.** Batch and rate-limit.
- **Using "unreliable" RPCs over WebSockets** thinking they'll be faster. They aren't.
- **No client-side interpolation** with low-frequency updates. Player positions look jerky.
- **No reconnection logic.** Network blip kicks the player out permanently.
- **Hardcoded server URLs.** Configure via build flag or runtime input.
- **Connecting without TLS in production.** Plaintext WebSockets are intercept-able.
- **No authentication on game server connections.** Anyone with the URL can join.
- **No rate limiting.** Clients spam RPCs and DoS the server.
- **Storing game state in scenes only on the host.** Host crashes → game lost.
- **No graceful shutdown.** Server kill leaves clients hanging.
- **No observability on the server.** Can't tell why it's running slowly or crashing.
- **Mixing P2P and server-authoritative patterns.** Inconsistent who-decides-what semantics.
- **Synchronizing things that don't need synchronizing.** Particle effects, audio, UI — can be local-only.
- **Replicating physics state** instead of inputs. Bandwidth-heavy and prone to divergence.
- **Long blocking operations on the server's main thread.** Stalls all clients.
- **No server-side logging of suspicious actions.** Can't detect or investigate cheating.
- **Different game logic on client and server.** Drift; cheating; debugging hell.

## Related

- [godot-fundamentals.md](godot-fundamentals.md) — `Node`, `MultiplayerApi`
- [signals-and-events.md](signals-and-events.md) — connection signals
- [security-engineering](../../security-engineering/SKILL.md) — server-side validation, anti-cheat
- system-architect — server architecture, scaling
- the `devops-engineer` agent — hosting the server
- [deployment-pipelines](../../deployment-pipelines/SKILL.md) — building and deploying the server
- site-reliability-engineering — running the server in production
- [godot-anti-patterns.md](godot-anti-patterns.md) — broader patterns to avoid
