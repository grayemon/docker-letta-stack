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
   docker-compose --file docker-compose.local.yaml up -d
   ```
   Uses: `lettabot.local.yaml` (includes letta-server)

   **Cloud mode (api.letta.com):**
   ```bash
   docker-compose --file docker-compose.cloud.yaml up -d
   ```
   Uses: `lettabot.cloud.yaml` (no letta-server)

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
docker-compose --file docker-compose.local.yaml up -d
```

Start with cloud API:
```bash
docker-compose --file docker-compose.cloud.yaml up -d
```

Stop services:
```bash
docker-compose --file docker-compose.local.yaml down
# Or
docker-compose --file docker-compose.cloud.yaml down
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

### Backup and Restore

**Scripts location:** `scripts/` directory

**Create a backup:**
```bash
# Make scripts executable (first time only)
chmod +x scripts/backup.sh

# Run backup (stops containers, creates compressed backup)
./scripts/backup.sh

# Options:
# --no-stop    Don't stop containers before backup
# --no-compress  Don't compress the backup
```

**List available backups:**
```bash
chmod +x scripts/list-backups.sh
./scripts/list-backups.sh
```

**Restore from backup:**
```bash
chmod +x scripts/restore.sh
./scripts/restore.sh letta-backup-2026-03-07.tar.gz

# Options:
# --no-stop      Don't stop containers before restore
# --no-start     Don't start containers after restore
# --dirs         Specific directories to restore (letta-server,letta-bot,letta-workspace)
# --list         List contents of backup without restoring
```

**Cleanup old backups:**
```bash
chmod +x scripts/cleanup-backups.sh
./scripts/cleanup-backups.sh           # Remove backups older than 7 days
./scripts/cleanup-backups.sh --days 30 # Remove backups older than 30 days
./scripts/cleanup-backups.sh --dry-run  # Show what would be deleted
```

**Important:** The `.env` file is not in the data directory and must be backed up separately!

### Monitoring and Logs

**Scripts location:** `scripts/` directory

**Health check:**
```bash
# Make scripts executable (first time only)
chmod +x scripts/monitor.sh

# Check all services
./scripts/monitor.sh

# Detailed output with CPU/memory
./scripts/monitor.sh --verbose

# Continuous monitoring
./scripts/monitor.sh --watch

# Check specific service
./scripts/monitor.sh --service letta-server
```

**View logs:**
```bash
chmod +x scripts/logs.sh

# View all logs (last 100 lines)
./scripts/logs.sh

# Filter by service
./scripts/logs.sh --service letta-server

# Filter by level (error, warn, info, debug)
./scripts/logs.sh --level error

# Follow logs in real-time
./scripts/logs.sh --follow

# Show timestamps
./scripts/logs.sh --timestamps
```

**Dashboard (HTML):**
Open `monitoring/dashboard.html` in a browser for a visual dashboard showing:
- Container status
- Resource usage (CPU/Memory)
- API health checks
- Recent logs

Note: The dashboard requires a backend API for full functionality. Use CLI scripts for now.

## 📁 Project Structure

```
.
├── docker-compose.yaml       # Service orchestration
├── Dockerfile.lettabot       # Bot container build
├── Dockerfile.workspace      # Workspace container build
├── .env.example              # Environment variable template
├── .env                      # Your actual environment (not in git)
├── lettabot.local.yaml        # Bot configuration (local server mode)
├── lettabot.cloud.yaml        # Bot configuration (cloud API mode)
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

### Bot Configuration

**Local server mode:** Edit `lettabot.local.yaml`
**Cloud API mode:** Edit `lettabot.cloud.yaml`

Customize:
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

**Common causes:**
1. **Invalid or expired bot token** - Bot token may be invalid or revoked
2. **Agent not created** - First message triggers agent creation (can take time)
3. **Telegram API issues** - Bot may be in webhook mode instead of polling
4. **Letta API connection** - Slow or failed connection to Letta server

**Troubleshooting steps:**

**1. Verify bot token:**
```bash
# Check your .env file
cat .env | grep TELEGRAM_BOT_TOKEN

# Verify token format (should look like: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz)
```

**2. Check Telegram bot status:**
```bash
# Open Telegram and message @BotFather
# Send /mybots to see all your bots
# Verify bot name and token match
```

**3. Check bot logs for errors:**
```bash
# Check for Telegram API errors (404, 401, etc.)
docker-compose --file docker-compose.local.yaml logs letta-bot --tail=50

# Look for specific error patterns:
# - "Call to 'getMe' failed" - Invalid token
# - "Bot polling error" - Token issues
# - "deleteWebhook failed" - Webhook configuration issue
```

**4. Verify agent status:**
```bash
# Check if agent exists in Letta
docker-compose --file docker-compose.local.yaml exec letta-bot lettabot model show

# If "No agent found", send a message to trigger creation
# First message will create agent automatically
```

**5. Restart bot with new token:**
```bash
# Update .env with new token
# Restart bot container
docker-compose --file docker-compose.local.yaml restart letta-bot

# Wait 30-60 seconds for bot to initialize
docker-compose --file docker-compose.local.yaml logs letta-bot --tail=30
```

**6. Check configuration file:**
```bash
# Verify lettabot config is correct
docker-compose --file docker-compose.local.yaml exec letta-bot cat /app/lettabot.yaml

# Check model configuration
# Ensure model is set correctly (e.g., openai/gpt-4o-mini)
```

**If you see Windows file lock errors (EBUSY), ensure `DATA_DIR=/app/data` is set in docker-compose (already configured here).**

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

## 📝 Development Diary

### [2026-03-01] Initial setup and profile-based configuration
- Created docker-letta-stack repository
- Added Docker Compose setup with letta-server, letta-bot, letta-workspace
- Implemented profile-based configuration (local vs cloud modes)
- Created separate config files: lettabot.local.yaml, lettabot.cloud.yaml
- Added comprehensive documentation in README.md
- Configured environment variables with clear mode selection

### [2026-03-01] Added tool update and reference documentation
- Added section on updating letta-code and lettabot
- Referenced resources/SKILL.md for detailed LettaBot commands
- Added model configuration instructions with profile support

### [2026-03-02] Fixed Telegram bot model configuration
- Resolved issue where bot was trying to use non-existent Anthropic model (anthropic/claude-sonnet-4-6)
- Created agent manually using Letta Code SDK with OpenAI model (openai/gpt-4o-mini)
- Updated lettabot.local.yaml to specify model: openai/gpt-4o-mini
- Cleaned up docker-compose.local.yaml to use environment variables consistently
- Successfully tested bot on Telegram - responding correctly

### [2026-03-07] Added backup/restore scripts for data portability
- Created scripts/backup.sh - Creates timestamped compressed backups
- Created scripts/restore.sh - Restores data from backup archives
- Created scripts/list-backups.sh - Lists available backups
- Created scripts/cleanup-backups.sh - Removes old backups
- Updated README.md with backup/restore usage instructions
- Scripts auto-stop containers for consistent database backups
- Supports selective directory restore and retention policies

### [2026-03-07] Added monitoring and logging setup
- Created scripts/monitor.sh - Health check and alerting script
- Created scripts/logs.sh - Log viewer with filtering
- Created monitoring/dashboard.html - Simple HTML monitoring dashboard
- Updated docker-compose files with logging configuration
- Docker log rotation (max 10MB per file, 3 files max)
- Added monitoring documentation to README.md

### [2026-03-07] Added FastAPI backend for dashboard
- Created monitoring/main.py - FastAPI server with API proxy
- Created monitoring/Dockerfile - Container configuration
- Updated docker-compose.local.yaml to include dashboard service
- Refactored dashboard.html into separate HTML, CSS, JS files
- Dashboard now proxies API calls to Letta Server in Docker network
- Dashboard accessible at http://localhost:8080
- Added Telegram setup documentation from lettabot docs

### [2026-03-07] Issues Identified and Being Addressed
- **Container Name Mismatch**: Backend expects `letta-server` but docker-compose uses `letta-core`
- **Environment Variable Mapping**: Backend expects `LETTA_SERVER_URL` but docker-compose sets `LETTA_BASE_URL`
- **Telegram Pairing**: API endpoints implemented but need frontend integration and Docker exec fixes
- **Error Handling**: Dashboard backend needs comprehensive error handling and validation
- **Cloud Mode Support**: Dashboard currently only supports local mode, cloud mode support needed
- **Script Robustness**: Shell scripts need improved error handling and cross-platform compatibility

### Future improvements
- [ ] Add GitHub Actions for automated testing
- [x] Add backup/restore scripts for data portability
- [x] Add monitoring and logging setup
- [ ] Explore multi-channel support (Slack, Discord, WhatsApp)

---

## 🛠️ Tool Management

### Update LettaBot Configuration

**Set model handle:**
```bash
# For local mode:
docker-compose --file docker-compose.local.yaml exec letta-bot lettabot model set openai/gpt-4o-mini

# Or for cloud mode:
docker-compose --file docker-compose.cloud.yaml exec letta-bot lettabot model set openai/gpt-4o-mini
```

**Interactive setup:**
```bash
docker-compose --file docker-compose.local.yaml exec letta-bot lettabot onboard
```

### Update Letta-Code

Letta-Code is pre-installed in the letta-workspace container. To update:

```bash
docker-compose --file docker-compose.local.yaml exec letta-workspace pip install --upgrade letta-code
# Or
docker-compose --file docker-compose.cloud.yaml exec letta-workspace pip install --upgrade letta-code
```

### Additional Resources

See [resources/SKILL.md](./resources/SKILL.md) for complete LettaBot command reference including:
- `lettabot onboard` - Interactive setup wizard
- `lettabot skills` - Manage skills
- `lettabot destroy` - Reset all data
- `lettabot help` - Show help

---

## 📄 License

MIT License - see LICENSE file for details.
