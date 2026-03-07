"""
Dashboard Backend - FastAPI Server
Proxies API requests to Letta Server running in Docker network
"""

from fastapi import FastAPI, Request
from fastapi.responses import FileResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import httpx
import os
import requests

app = FastAPI(title="Letta Dashboard API")

# Enable CORS for all origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Letta Server URL - defaults to Docker network address
LETTA_SERVER = os.getenv("LETTA_SERVER_URL", "http://letta-core:8283")

# Docker API URL - try different options for Windows Docker Desktop
def get_docker_url():
    # Try host.docker.internal for Windows
    return "http://host.docker.internal:2375"


@app.get("/")
async def root():
    """Serve the main dashboard HTML"""
    return FileResponse("dashboard.html")


@app.get("/dashboard.css")
async def styles():
    """Serve dashboard styles"""
    return FileResponse("dashboard.css")


@app.get("/dashboard.js")
async def scripts():
    """Serve dashboard JavaScript"""
    return FileResponse("dashboard.js")


# ====================
# Proxy API Endpoints
# ====================

@app.get("/api/agents")
async def list_agents():
    """List all agents on Letta Server"""
    async with httpx.AsyncClient(timeout=30.0, follow_redirects=True) as client:
        response = await client.get(f"{LETTA_SERVER}/v1/agents")
        return JSONResponse(content=response.json(), status_code=response.status_code)


@app.post("/api/agents")
async def create_agent(request: Request):
    """Create a new agent on Letta Server"""
    body = await request.json()
    async with httpx.AsyncClient(timeout=60.0, follow_redirects=True) as client:
        response = await client.post(f"{LETTA_SERVER}/v1/agents", json=body)
        return JSONResponse(content=response.json(), status_code=response.status_code)


@app.get("/api/agents/{agent_id}")
async def get_agent(agent_id: str):
    """Get details of a specific agent"""
    async with httpx.AsyncClient(timeout=30.0, follow_redirects=True) as client:
        response = await client.get(f"{LETTA_SERVER}/v1/agents/{agent_id}")
        return JSONResponse(content=response.json(), status_code=response.status_code)


@app.delete("/api/agents/{agent_id}")
async def delete_agent(agent_id: str):
    """Delete an agent"""
    async with httpx.AsyncClient(timeout=30.0, follow_redirects=True) as client:
        response = await client.delete(f"{LETTA_SERVER}/v1/agents/{agent_id}")
        return JSONResponse(
            content=response.json() if response.text else {},
            status_code=response.status_code
        )


@app.get("/api/models")
async def list_models():
    """List available models on Letta Server"""
    async with httpx.AsyncClient(timeout=30.0, follow_redirects=True) as client:
        response = await client.get(f"{LETTA_SERVER}/v1/models")
        return JSONResponse(content=response.json(), status_code=response.status_code)


@app.get("/api/health")
async def health_check():
    """Check health of Letta Server"""
    try:
        async with httpx.AsyncClient(timeout=10.0, follow_redirects=True) as client:
            response = await client.get(f"{LETTA_SERVER}/v1/agents")
            is_ok = 200 <= response.status_code < 300
            return {
                "status": "ok" if is_ok else "error",
                "letta_server": is_ok,
                "message": "Letta Server is reachable" if is_ok else f"Letta Server returned: {response.status_code}"
            }
    except Exception as e:
        return {
            "status": "error",
            "letta_server": False,
            "message": f"Cannot connect to Letta Server: {str(e)}"
        }


# ====================
# Telegram Bot API
# ====================

@app.get("/api/telegram/validate/{token}")
async def validate_telegram_bot(token: str):
    """Validate Telegram bot token using Telegram API"""
    async with httpx.AsyncClient(timeout=10.0) as client:
        response = await client.get(f"https://api.telegram.org/bot{token}/getMe")
        return JSONResponse(content=response.json(), status_code=response.status_code)


# ====================
# Telegram Pairing API
# ====================

@app.get("/api/pairing/list")
async def list_pairing():
    """List pending Telegram pairing requests using Docker REST API"""
    try:
        docker_url = get_docker_url()
        
        # Get container ID
        container_url = f"{docker_url}/containers/json?filters={{\"name\":[\"letta-bot\"]}}"
        containers = requests.get(container_url, timeout=10).json()
        
        if not containers or len(containers) == 0:
            return {
                "success": False,
                "output": None,
                "error": "letta-bot container not found. Make sure Docker is running."
            }
        
        container_id = containers[0]["Id"]
        
        # Execute the pairing list command
        exec_url = f"{docker_url}/containers/{container_id}/exec"
        exec_config = {
            "AttachStdout": True,
            "AttachStderr": True,
            "Cmd": ["lettabot", "pairing", "list", "telegram"],
            "Tty": False
        }
        
        # Create exec instance
        exec_resp = requests.post(exec_url, json=exec_config, timeout=10).json()
        
        if "Id" not in exec_resp:
            return {
                "success": False,
                "output": None,
                "error": "Failed to create exec: " + str(exec_resp)
            }
        
        exec_id = exec_resp["Id"]
        
        # Start exec
        start_url = f"{docker_url}/exec/{exec_id}/start"
        start_resp = requests.post(start_url, json={"Detach": False, "Tty": False}, timeout=30)
        
        # Parse output - remove null bytes and get clean output
        output = start_resp.text.replace('\x00', '').strip()
        
        return {
            "success": True,
            "output": output if output else "No pending pairing requests",
            "error": None
        }
    except Exception as e:
        return {
            "success": False,
            "output": None,
            "error": str(e)
        }


@app.post("/api/pairing/approve")
async def approve_pairing(request: Request):
    """Approve a Telegram pairing code using Docker REST API"""
    try:
        body = await request.json()
        code = body.get("code", "")
        
        if not code:
            return {
                "success": False,
                "output": None,
                "error": "Pairing code is required"
            }
        
        docker_url = get_docker_url()
        
        # Get container ID
        container_url = f"{docker_url}/containers/json?filters={{\"name\":[\"letta-bot\"]}}"
        containers = requests.get(container_url, timeout=10).json()
        
        if not containers or len(containers) == 0:
            return {
                "success": False,
                "output": None,
                "error": "letta-bot container not found"
            }
        
        container_id = containers[0]["Id"]
        
        # Execute the pairing approve command
        exec_url = f"{docker_url}/containers/{container_id}/exec"
        exec_config = {
            "AttachStdout": True,
            "AttachStderr": True,
            "Cmd": ["lettabot", "pairing", "approve", "telegram", code],
            "Tty": False
        }
        
        exec_resp = requests.post(exec_url, json=exec_config, timeout=10).json()
        
        if "Id" not in exec_resp:
            return {
                "success": False,
                "output": None,
                "error": "Failed to create exec: " + str(exec_resp)
            }
        
        exec_id = exec_resp["Id"]
        
        start_url = f"{docker_url}/exec/{exec_id}/start"
        start_resp = requests.post(start_url, json={"Detach": False, "Tty": False}, timeout=30)
        
        output = start_resp.text.replace('\x00', '').strip()
        
        return {
            "success": True,
            "output": output if output else "Pairing approved!",
            "error": None
        }
    except Exception as e:
        return {
            "success": False,
            "output": None,
            "error": str(e)
        }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
