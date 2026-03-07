#!/bin/bash
# ============================================
# Docker Letta Stack - Backup Script
# Creates timestamped backups of all data
# ============================================

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${PROJECT_DIR}/backups"
DATA_DIR="${PROJECT_DIR}/data"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_NAME="letta-backup-${TIMESTAMP}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Windows (Git Bash or similar)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

# Parse arguments
STOP_CONTAINERS=true
COMPRESS=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-stop)
            STOP_CONTAINERS=false
            shift
            ;;
        --no-compress)
            COMPRESS=false
            shift
            ;;
        *)
            echo_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo_info "Starting backup: $BACKUP_NAME"
echo_info "Backup directory: $BACKUP_DIR"

# Stop containers to ensure consistent database state
if [ "$STOP_CONTAINERS" = true ]; then
    echo_info "Stopping Docker containers..."
    cd "$PROJECT_DIR"
    
    # Try local compose first, then cloud
    if [ -f "docker-compose.local.yaml" ]; then
        $DOCKER_COMPOSE -f docker-compose.local.yaml stop 2>/dev/null || true
    fi
    if [ -f "docker-compose.cloud.yaml" ]; then
        $DOCKER_COMPOSE -f docker-compose.cloud.yaml stop 2>/dev/null || true
    fi
    if [ -f "docker-compose.yaml" ]; then
        $DOCKER_COMPOSE -f docker-compose.yaml stop 2>/dev/null || true
    fi
    
    echo_info "Containers stopped"
fi

# Create backup
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

echo_info "Backing up data directory..."
cp -r "$DATA_DIR" "$BACKUP_PATH"

# Create metadata file
cat > "${BACKUP_PATH}/backup-info.json" << EOF
{
    "name": "${BACKUP_NAME}",
    "timestamp": "${TIMESTAMP}",
    "date": "$(date -Iseconds)",
    "hostname": "${HOSTNAME:-unknown}",
    "retention_days": ${RETENTION_DAYS},
    "data_directories": [
        "letta-server",
        "letta-bot",
        "letta-workspace"
    ]
}
EOF

# Compress if requested
if [ "$COMPRESS" = true ]; then
    echo_info "Compressing backup..."
    cd "$BACKUP_DIR"
    tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}"
    rm -rf "$BACKUP_PATH"
    FINAL_BACKUP="${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
    echo_info "Backup created: $FINAL_BACKUP"
else
    echo_info "Backup created (uncompressed): $BACKUP_PATH"
    FINAL_BACKUP="$BACKUP_PATH"
fi

# Start containers again
if [ "$STOP_CONTAINERS" = true ]; then
    echo_info "Starting Docker containers..."
    cd "$PROJECT_DIR"
    
    if [ -f "docker-compose.local.yaml" ]; then
        $DOCKER_COMPOSE -f docker-compose.local.yaml start 2>/dev/null || true
    fi
    if [ -f "docker-compose.cloud.yaml" ]; then
        $DOCKER_COMPOSE -f docker-compose.cloud.yaml start 2>/dev/null || true
    fi
    if [ -f "docker-compose.yaml" ]; then
        $DOCKER_COMPOSE -f docker-compose.yaml start 2>/dev/null || true
    fi
    
    echo_info "Containers started"
fi

# Cleanup old backups
echo_info "Cleaning up backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -name "letta-backup-*.tar.gz" -mtime +${RETENTION_DAYS} -delete 2>/dev/null || true
find "$BACKUP_DIR" -type d -name "letta-backup-*" -mtime +${RETENTION_DAYS} -exec rm -rf {} \; 2>/dev/null || true

echo_info "Backup complete!"
echo_info "Backup file: $FINAL_BACKUP"

# Show backup size
du -h "$FINAL_BACKUP" | cut -f1
