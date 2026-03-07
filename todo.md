# TODO - Docker Letta Stack

## Priority List

### 🔴 High Priority

- [ ] **Fix Container Name Mismatch**
  - Description: Backend expects `letta-server` but docker-compose uses `letta-core`
  - Status: In Progress
  - Update monitoring/main.py to use correct container hostname
  - Update docker-compose.local.yaml service names for consistency

- [ ] **Implement Telegram Pairing in Dashboard**
  - Description: Add API endpoints to list/approve Telegram pairings from dashboard
  - Status: In Progress
  - Update main.py with pairing endpoints
  - Update dashboard.js to use the API
  - Fix Docker exec commands for pairing functionality

- [ ] **Fix Environment Variable Mapping**
  - Description: Backend expects `LETTA_SERVER_URL` but docker-compose sets `LETTA_BASE_URL`
  - Status: Pending
  - Update environment variable passing in docker-compose
  - Ensure consistent variable naming across services

- [ ] **Improve Error Handling**
  - Description: Add comprehensive error handling to dashboard backend
  - Status: Pending
  - Add proper exception handling in FastAPI endpoints
  - Improve error messages and status codes
  - Add validation for API requests

### 🟡 Medium Priority

- [ ] **Add Cloud Mode Support**
  - Description: Extend dashboard to work with cloud mode configuration
  - Status: Pending
  - Update dashboard to detect and handle cloud vs local mode
  - Add configuration for cloud API endpoints

- [ ] **Enhance Script Robustness**
  - Description: Improve error handling and terminal compatibility in shell scripts
  - Status: Pending
  - Fix ANSI color code issues
  - Add better error handling and validation
  - Improve cross-platform compatibility

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
- **Issues Identified:**
  - Container name mismatch between backend and docker-compose
  - Environment variable mapping inconsistencies
  - Telegram pairing functionality needs completion
  - Error handling needs improvement
  - Cloud mode support missing from dashboard
