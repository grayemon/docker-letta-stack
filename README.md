# 🐳 Docker Letta Stack

Self-hosted Letta infrastructure using Docker Compose. Run your own Letta server, Telegram bot, and development environment with full data persistence and portability.

## 🎯 What This Is

A complete Docker Compose setup that includes:

- **letta-server** - Letta server with PostgreSQL data persistence
- **letta-bot** - Telegram bot with Letta integration
- **letta-workspace** - Development environment (Python, TypeScript, HTML, CSS)

All services run on a Docker network with health checks and persistent volumes. Perfect for portable deployment (copy to USB and run anywhere).

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose installed
- OpenAI API key (or other LLM provider)
- Telegram account

### Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/grayemon/docker-letta-stack.git
   cd docker-letta-stack
   ```

2. **Configure environment variables:**
   ```bash
   cp .env.example .env
   ```

   Edit `.env` with your credentials:
   ```bash
   LETTA_API_KEY=letta-your-api-key-here
   OPENAI_API_KEY=sk-your-openai-key-here
   TELEGRAM_BOT_TOKEN=your-telegram-bot-token-here
   ```

   **Choose your mode:**

   **Cloud mode (api.letta.com):**
   - `LETTA_API_KEY` required
   - `LETTA_BASE_URL` optional (defaults to https://api.letta.com)
   - `OPENAI_API_KEY` optional (if using Letta cloud with your own key)

   **Local mode (letta-server):**
   - `OPENAI_API_KEY` required
   - `LETTA_BASE_URL` required: `http://letta-server:8283`
   - `LETTA_API_KEY` optional (if using local server with your own key)

   Configuration files:
   - `lettabot.cloud.yaml` - Used for cloud mode
   - `lettabot.local.yaml` - Used for local server mode
   - Docker Compose automatically mounts the correct file based on profile

3. **Get a Telegram bot token:**
   - Open Telegram and message [@BotFather](https://t.me/BotFather)
   - Send `/newbot` and follow the prompts
   - Copy the bot token (looks like `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

4. **Start services:**

   **Local mode (with letta-server):**
   ```bash
   docker-compose --profile local up -d
   ```
   Uses: `lettabot.local.yaml`

   **Cloud mode (api.letta.com):**
   ```bash
   docker-compose --profile cloud up -d
   ```
   Uses: `lettabot.cloud.yaml`

   **All services (default):**
   ```bash
   docker-compose up -d
   ```
   Uses: `lettabot.local.yaml` (same as local mode)

5. **Verify services are running:**
   ```bash
   docker-compose ps
   curl http://localhost:8283/v1/health
   ```

6. **Chat with your bot:**
   - Open Telegram and message your bot
   - Try: "Hello!" or "What can you help me with?"

## 📋 Commands

### Docker Compose Profiles

**Profiles available:**
- `local` - Includes letta-server, letta-bot, letta-workspace
- `cloud` - letta-bot and letta-workspace only (connects to api.letta.com)
- Default (no profile) - All services (same as `local`)

**Usage:**

Start with local server:
```bash
docker-compose --profile local up -d
```

Start with cloud API:
```bash
docker-compose --profile cloud up -d
```

Start all services (default):
```bash
docker-compose up -d
```

### Docker Compose

- `docker-compose up -d` - Start all services
- `docker-compose down` - Stop all services
- `docker-compose logs -f [service]` - View logs for a service
- `docker-compose ps` - Check service status
- `docker-compose restart [service]` - Restart a specific service

### Health Checks

Check letta-server health:
```bash
curl http://localhost:8283/v1/health
```

## 📁 Project Structure

```
.
├── docker-compose.yaml       # Service orchestration
├── Dockerfile.lettabot       # Bot container build
├── Dockerfile.workspace      # Workspace container build
├── .env.example              # Environment variable template
├── .env                      # Your actual environment (not in git)
├── lettabot.yaml             # Bot configuration
└── data/                     # Persistent data (not in git)
    ├── letta-server/         # PostgreSQL database
    ├── letta-bot/            # Bot application data
    │   └── lettabot-agent.json  # Agent state (auto-created)
    └── letta-workspace/      # Development workspace files
```

## ⚙️ Configuration

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `LETTA_BASE_URL` | No | Internal Docker network URL (Compose uses `http://letta-server:8283`) |
| `OPENAI_API_KEY` | Yes | OpenAI API key for LLM access |
| `TELEGRAM_BOT_TOKEN` | Yes | From @BotFather on Telegram |
| `ALLOWED_USERS` | No | Comma-separated Telegram user IDs to restrict access |
| `DATA_DIR` | No | Persistent data dir for LettaBot (default: `/app`) |

### Bot Configuration (lettabot.yaml)

Edit `lettabot.yaml` to customize:
- Agent name (model handle is set via CLI)
- Channel settings (Telegram, Slack, Discord)
- Feature toggles (cron, heartbeat)
- Working directory

Set the model handle after first message:
```bash
docker-compose exec letta-bot lettabot model set openai/gpt-4o-mini
```

## 🏗️ Services

### letta-server

- **Image:** `letta/letta:0.16.5`
- **Port:** 8283 (mapped to host)
- **Health Check:** HTTP endpoint `/v1/health`
- **Data:** PostgreSQL database in `./data/letta-server`

### letta-bot

- **Dockerfile:** `Dockerfile.lettabot`
- **Depends on:** letta-server
- **Health Check:** Node.js process check
- **Data:** Application data in `./data/letta-bot`

### letta-workspace

- **Dockerfile:** `Dockerfile.workspace`
- **Depends on:** letta-server, letta-bot
- **Health Check:** Python process check
- **Data:** Workspace files in `./data/letta-workspace`
- **Tools:** git, nodejs, python, letta-code

## 🔧 Troubleshooting

### Services won't start

```bash
# Check logs
docker-compose logs -f

# Check service status
docker-compose ps

# Restart a service
docker-compose restart letta-server
```

### Connection refused to letta-server

```bash
# Verify server is running
curl http://localhost:8283/v1/health

# Check server logs
docker-compose logs letta-server
```

### Bot not responding

```bash
# Check bot logs
docker-compose logs letta-bot

# Verify configuration
docker-compose exec letta-bot cat /app/lettabot.yaml
```

If you see Windows file lock errors (EBUSY), ensure `DATA_DIR=/app/data` is set in docker-compose (already configured here).

### Reset everything

```bash
# Stop and remove containers
docker-compose down

# Remove data (WARNING: deletes all data)
rm -rf ./data

# Restart fresh
docker-compose up -d
```

## 💾 Portability

All data is stored in `./data/` directory. You can copy the entire project (including `.env`) to a USB drive and run it on any machine with Docker installed.

To move to another machine:
1. Stop services: `docker-compose down`
2. Copy entire project directory to USB
3. Copy to new machine
4. Start services: `docker-compose up -d`

## 📊 Hardware Requirements

**Minimum:**
- 2GB RAM
- 2 CPU cores
- 10GB disk space

**Recommended:**
- 4GB RAM
- 4 CPU cores
- 20GB disk space

Note: GPU is not required when using cloud LLMs (OpenAI, Anthropic).

## 🔒 Security Considerations

1. **Network exposure:** Port 8283 is exposed to localhost only. Don't expose to internet without authentication.
2. **API keys:** Never commit `.env` to version control (already in `.gitignore`).
3. **Tool permissions:** Review which tools your agent has access to (Bash can execute arbitrary commands).
4. **User restrictions:** Use `ALLOWED_USERS` to limit who can interact with your bot.

## 🌐 Network Configuration

Services communicate via Docker network named `letta-network`:

- Internal URL: `http://letta-server:8283`
- External access: `http://localhost:8283`

**Important:** Use `letta-server` hostname in `LETTA_BASE_URL`, NOT `localhost`.

## 📚 Resources

- [Letta Documentation](https://docs.letta.com)
- [Letta Discord](https://discord.gg/letta)
- [GitHub Issues](https://github.com/letta-ai/letta/issues)

## 🤝 Contributing

Contributions welcome! Feel free to submit issues and pull requests.

## 📄 License

MIT License - see LICENSE file for details.
