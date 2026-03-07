"""
Dashboard Backend - FastAPI Server
Proxies API requests to Letta Server running in Docker network
"""

from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import FileResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from fastapi.responses import PlainTextResponse
import httpx
import os
import subprocess
import logging
from typing import Optional

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Letta Dashboard API")

# Enable CORS for all origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Letta Server URL - defaults to Docker network address
LETTA_SERVER = os.getenv("LETTA_SERVER_URL", "http://letta-server:8283")

# Global HTTP client with connection pooling
http_client = httpx.AsyncClient(timeout=httpx.Timeout(30.0, connect=10.0), follow_redirects=True)


@app.on_event("shutdown")
async def shutdown_event():
    """Clean up HTTP client on shutdown"""
    await http_client.aclose()


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request, exc):
    """Handle validation errors"""
    logger.error(f"Validation error: {exc}")
    return JSONResponse(
        status_code=400,
        content={"error": "Invalid request format", "details": str(exc)}
    )


@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    """Handle general exceptions"""
    logger.error(f"Unhandled exception: {exc}")
    return JSONResponse(
        status_code=500,
        content={"error": "Internal server error", "message": str(exc)}
    )


@app.get("/")
async def root():
    """Serve the main dashboard HTML"""
    try:
        return FileResponse("dashboard.html")
    except Exception as e:
        logger.error(f"Error serving dashboard.html: {e}")
        raise HTTPException(status_code=500, detail="Dashboard file not found")


@app.get("/dashboard.css")
async def styles():
    """Serve dashboard styles"""
    try:
        return FileResponse("dashboard.css")
    except Exception as e:
        logger.error(f"Error serving dashboard.css: {e}")
        raise HTTPException(status_code=500, detail="CSS file not found")


@app.get("/dashboard.js")
async def scripts():
    """Serve dashboard JavaScript"""
    try:
        return FileResponse("dashboard.js")
    except Exception as e:
        logger.error(f"Error serving dashboard.js: {e}")
        raise HTTPException(status_code=500, detail="JavaScript file not found")


# ====================
# Helper Functions
# ====================

async def make_api_request(method: str, endpoint: str, data: Optional[dict] = None):
    """Make HTTP request to Letta Server with error handling"""
    try:
        url = f"{LETTA_SERVER}{endpoint}"
        logger.info(f"Making {method} request to {url}")
        
        if method.upper() == "GET":
            response = await http_client.get(url)
        elif method.upper() == "POST":
            response = await http_client.post(url, json=data)
        elif method.upper() == "DELETE":
            response = await http_client.delete(url)
        else:
            raise HTTPException(status_code=400, detail=f"Unsupported HTTP method: {method}")
        
        # Log response status
        logger.info(f"Response status: {response.status_code}")
        
        # Handle different response types
        if response.status_code == 204:  # No content
            return {"status": "success", "message": "Operation completed"}
        
        try:
            content = response.json()
        except Exception:
            content = {"message": response.text}
        
        return JSONResponse(content=content, status_code=response.status_code)
        
    except httpx.ConnectTimeout:
        logger.error(f"Connection timeout to Letta Server at {LETTA_SERVER}")
        raise HTTPException(status_code=504, detail="Connection timeout to Letta Server")
    except httpx.ConnectError:
        logger.error(f"Connection error to Letta Server at {LETTA_SERVER}")
        raise HTTPException(status_code=503, detail="Cannot connect to Letta Server")
    except httpx.HTTPStatusError as e:
        logger.error(f"HTTP error {e.response.status_code} from Letta Server")
        raise HTTPException(status_code=e.response.status_code, detail=f"Letta Server error: {e}")
    except Exception as e:
        logger.error(f"Unexpected error in API request: {e}")
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")


def run_docker_command(command: list, timeout: int = 30):
    """Run Docker command with error handling"""
    try:
        logger.info(f"Running Docker command: {' '.join(command)}")
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        
        logger.info(f"Docker command completed with return code: {result.returncode}")
        if result.stderr:
            logger.warning(f"Docker command stderr: {result.stderr}")
        
        return {
            "success": result.returncode == 0,
            "stdout": result.stdout.strip() if result.stdout else "",
            "stderr": result.stderr.strip() if result.stderr else "",
            "returncode": result.returncode
        }
    except subprocess.TimeoutExpired:
        logger.error(f"Docker command timed out after {timeout} seconds")
        return {
            "success": False,
            "stdout": "",
            "stderr": f"Command timed out after {timeout} seconds",
            "returncode": -1
        }
    except Exception as e:
        logger.error(f"Error running Docker command: {e}")
        return {
            "success": False,
            "stdout": "",
            "stderr": str(e),
            "returncode": -1
        }


# ====================
# Proxy API Endpoints
# ====================

@app.get("/api/agents")
async def list_agents():
    """List all agents on Letta Server"""
    return await make_api_request("GET", "/v1/agents")


@app.post("/api/agents")
async def create_agent(request: Request):
    """Create a new agent on Letta Server"""
    try:
        body = await request.json()
        logger.info(f"Creating agent with body: {body}")
        return await make_api_request("POST", "/v1/agents", body)
    except Exception as e:
        logger.error(f"Error creating agent: {e}")
        raise HTTPException(status_code=400, detail=f"Invalid request body: {str(e)}")


@app.get("/api/agents/{agent_id}")
async def get_agent(agent_id: str):
    """Get details of a specific agent"""
    return await make_api_request("GET", f"/v1/agents/{agent_id}")


@app.delete("/api/agents/{agent_id}")
async def delete_agent(agent_id: str):
    """Delete an agent"""
    return await make_api_request("DELETE", f"/v1/agents/{agent_id}")


@app.get("/api/models")
async def list_models():
    """List available models on Letta Server"""
    return await make_api_request("GET", "/v1/models")


@app.get("/api/health")
async def health_check():
    """Check health of Letta Server"""
    try:
        response = await http_client.get(f"{LETTA_SERVER}/v1/health")
        is_ok = 200 <= response.status_code < 300
        return {
            "status": "ok" if is_ok else "error",
            "letta_server": is_ok,
            "message": "Letta Server is reachable" if is_ok else f"Letta Server returned: {response.status_code}",
            "server_url": LETTA_SERVER,
            "status_code": response.status_code
        }
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return {
            "status": "error",
            "letta_server": False,
            "message": f"Cannot connect to Letta Server: {str(e)}",
            "server_url": LETTA_SERVER
        }


# ====================
# Telegram Bot API
# ====================

@app.get("/api/telegram/validate/{token}")
async def validate_telegram_bot(token: str):
    """Validate Telegram bot token using Telegram API"""
    try:
        if not token or len(token) < 10:
            raise HTTPException(status_code=400, detail="Invalid bot token format")
        
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(f"https://api.telegram.org/bot{token}/getMe")
            return JSONResponse(content=response.json(), status_code=response.status_code)
    except httpx.ConnectTimeout:
        raise HTTPException(status_code=504, detail="Telegram API timeout")
    except Exception as e:
        logger.error(f"Telegram validation error: {e}")
        raise HTTPException(status_code=500, detail=f"Telegram API error: {str(e)}")


# ====================
# Telegram Pairing API
# ====================

@app.get("/api/pairing/list")
async def list_pairing():
    """List pending Telegram pairing requests using Docker exec"""
    try:
        result = run_docker_command(["docker", "exec", "letta-bot", "lettabot", "pairing", "list", "telegram"])
        
        if result["success"]:
            return {
                "success": True,
                "output": result["stdout"] or "No pending pairing requests",
                "error": result["stderr"] if result["stderr"] else None
            }
        else:
            return {
                "success": False,
                "output": None,
                "error": result["stderr"] or "Failed to list pairing requests"
            }
    except Exception as e:
        logger.error(f"Pairing list error: {e}")
        return {
            "success": False,
            "output": None,
            "error": f"Unexpected error: {str(e)}"
        }


@app.post("/api/pairing/approve")
async def approve_pairing(request: Request):
    """Approve a Telegram pairing code using Docker exec"""
    try:
        body = await request.json()
        code = body.get("code", "").strip()

        if not code:
            return {
                "success": False,
                "output": None,
                "error": "Pairing code is required"
            }

        if len(code) < 3:
            return {
                "success": False,
                "output": None,
                "error": "Pairing code appears to be invalid (too short)"
            }

        result = run_docker_command([
            "docker", "exec", "letta-bot", "lettabot", 
            "pairing", "approve", "telegram", code
        ])
        
        if result["success"]:
            return {
                "success": True,
                "output": result["stdout"] or "Pairing approved!",
                "error": result["stderr"] if result["stderr"] else None
            }
        else:
            return {
                "success": False,
                "output": None,
                "error": result["stderr"] or "Failed to approve pairing"
            }
    except Exception as e:
        logger.error(f"Pairing approval error: {e}")
        return {
            "success": False,
            "output": None,
            "error": f"Unexpected error: {str(e)}"
        }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
