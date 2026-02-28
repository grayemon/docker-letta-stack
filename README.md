# Letta Bot - Self-Hosted Infrastructure

Docker Compose setup for self-hosted Letta services.

## Services

- **letta-server** - Letta server with PostgreSQL data persistence
- **letta-bot** - Telegram bot with Letta integration
- **letta-workspace** - Development environment (Python, TypeScript, HTML, CSS)

## Quick Start

1. Copy environment variables:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` with your API keys:
   - `OPENAI_API_KEY` - OpenAI API key
   - `TELEGRAM_BOT_TOKEN` - Get from @BotFather on Telegram

3. Start services:
   ```bash
   docker-compose up -d
   ```

4. Check health:
   ```bash
   curl http://localhost:8283/v1/health
   ```

## Commands

- `docker-compose up -d` - Start all services
- `docker-compose down` - Stop all services
- `docker-compose logs -f [service]` - View logs
- `docker-compose ps` - Check service status

## Project Structure

```
.
├── docker-compose.yaml       # Service orchestration
├── Dockerfile.lettabot       # Bot container build
├── Dockerfile.workspace      # Workspace container build
├── .env.example              # Environment variable template
├── lettabot.yaml             # Bot configuration
├── lettabot-agent.json       # Agent configuration
└── data/                     # Persistent data (not in git)
    ├── letta-server/
    ├── letta-bot/
    └── letta-workspace/
```

## Portability

All data is stored in `./data/` directory. You can copy the entire project (including `.env`) to a USB for portable deployment.
