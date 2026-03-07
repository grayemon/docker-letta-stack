# Implementation Plan: Dashboard Telegram Pairing

## Task: Enable Telegram Pairing from Dashboard

### How Pairing Works (from lettabot docs):
1. User messages bot on Telegram with `/start`
2. Bot sends pairing code to user
3. Admin approves with: `lettabot pairing approve telegram <CODE>`
4. **LettaBot automatically notifies user** of successful pairing
5. User can then chat with the bot

### Implementation:

#### 1. Update monitoring/main.py
Add API endpoints:
```python
import subprocess

@app.get("/api/pairing/list")
async def list_pairing():
    """List pending Telegram pairing requests"""
    result = subprocess.run(
        ["docker", "exec", "letta-bot", "lettabot", "pairing", "list", "telegram"],
        capture_output=True, text=True
    )
    return {"output": result.stdout, "error": result.stderr}

@app.post("/api/pairing/approve")
async def approve_pairing(request: Request):
    """Approve a Telegram pairing code"""
    body = await request.json()
    code = body.get("code", "")
    result = subprocess.run(
        ["docker", "exec", "letta-bot", "lettabot", "pairing", "approve", "telegram", code],
        capture_output=True, text=True
    )
    return {"output": result.stdout, "error": result.stderr, "success": result.returncode == 0}
```

#### 2. Update monitoring/dashboard.js
- Update `checkPairing()` to call `/api/pairing/list`
- Update `approvePairing()` to call `/api/pairing/approve`

#### 3. Rebuild dashboard container
- Rebuild with new main.py
- Restart container

### LettaBot Commands:
- `docker exec letta-bot lettabot pairing list telegram` - List pending
- `docker exec letta-bot lettabot pairing approve telegram <CODE>` - Approve

### Notification:
LettaBot automatically notifies the user on successful pairing (no additional work needed).
