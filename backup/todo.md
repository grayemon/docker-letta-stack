# TODO - Docker Letta Stack

## Priority List

### 🔴 High Priority

- [ ] **Implement Telegram Pairing in Dashboard**
  - Description: Add API endpoints to list/approve Telegram pairings from dashboard
  - Status: In Progress
  - Update main.py with pairing endpoints
  - Update dashboard.js to use the API

### 🟢 Lower Priority

- [ ] **Add GitHub Actions for automated testing**
  - Description: Set up CI/CD pipeline to test Docker Compose configurations
  - Status: Pending

- [ ] **Explore multi-channel support (Slack, Discord, WhatsApp)**
  - Description: Add support for additional messaging platforms beyond Telegram
  - Status: Pending

---

## Recent Changes (2026-03-07)

- Created FastAPI backend for dashboard
- Dashboard now proxies API calls to Letta Server in Docker network
- Dashboard is accessible at http://localhost:8080
- Added Telegram setup documentation from lettabot docs
