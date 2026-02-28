# What I want to create

services

1. letta-server
2. letta-bot
3. letta-workspace

## letta-server

- must have health checks curl <http://localhost:8283/v1/health>
- on a docker network
- volumes on ./data/letta-server

## letta-bot

- volumes on ./data/letta-bot
- depends on letta-server
- on a docker network
- must have health checks
- must have lettabot installed
- letta_base_url from .env

## letta-workspace (coding development environment for python, typescript, html, css)

- volumes on ./data/letta-workspace
- depends on letta-server
- depends on letta-bot
- on a docker network
- must have health checks
- must have git, nodejs, python
- must have letta-code installed
- letta_base_url from .env

## Docker

- docker-compose.yaml
  - respects .env
  - must have health checks
  - ports
  - volumes (this must be portable can be copied to usb)
  - networks
  - depends on
- dockerfile (if necessary)
- .env.example

## Environment variables

- LETTA_BASE_URL (optional if i want to use letta-server, because it automatically connects to api.letta.com)
- OPENAI_API_KEY
- other keys to be added when needed
- TELEGRAM_BOT_TOKEN
- ALLOWED_USERS
- WORKING_DIR
- LETTA_CLI_PATH

## Use this files for reference

./getting-started.md
./selfhosted-setup.md
