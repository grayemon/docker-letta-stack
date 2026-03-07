#!/bin/bash
# ============================================
# Docker Letta Stack - Restore Script
# Restores data from backup archives
# ============================================

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${PROJECT_DIR}/backups"
DATA_DIR="${PROJECT_DIR}/data"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

echo_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if running on Windows (Git Bash or similar)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

# Show usage
usage() {
    echo "Usage: $0 <backup-file> [options]"
    echo ""
    echo "Arguments:"
    echo "  backup-file     Path to backup file (tar.gz or directory)"
    echo ""
    echo "Options:"
    echo "  --no-stop       Don't stop containers before restore"
    echo "  --no-start      Don't start containers after restore"
    echo "  --dirs          Specific directories to restore (letta-server,letta-bot,letta-workspace)"
    echo "  --list          List contents of backup without restoring"
    echo ""
    echo "Examples:"
    echo "  $0 letta-backup-2026-03-07.tar.gz"
    echo "  $0 letta-backup-2026-03-07.tar.gz --dirs letta-server,letta-bot"
    echo "  $0 letta-backup-2026-03-07.tar.gz --list"
    exit 1
}

# Parse arguments
STOP_CONTAINERS=true
START_CONTAINERS=true
SPECIFIC_DIRS=""
LIST_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-stop)
            STOP_CONTAINERS=false
            shift
            ;;
        --no-start)
            START_CONTAINERS=false
            shift
            ;;
        --dirs)
            SPECIFIC_DIRS="$2"
            shift 2
            ;;
        --list)
            LIST_ONLY=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            if [ -z "$BACKUP_FILE" ]; then
                BACKUP_FILE="$1"
            else
                echo_error "Unknown option: $1"
                usage
            fi
            shift
            ;;
    esac
done

# Validate backup file
if [ -z "$BACKUP_FILE" ]; then
    echo_error "No backup file specified"
    usage
fi

# Resolve backup file path
if [ -f "$BACKUP_FILE" ]; then
    FULL_BACKUP_PATH="$BACKUP_FILE"
elif [ -f "${BACKUP_DIR}/${BACKUP_FILE}" ]; then
    FULL_BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILE}"
elif [ -d "$BACKUP_FILE" ]; then
    FULL_BACKUP_PATH="$BACKUP_FILE"
elif [ -d "${BACKUP_DIR}/${BACKUP_FILE}" ]; then
    FULL_BACKUP_DIR="${BACKUP_DIR}/${BACKUP_FILE}"
else
    echo_error "Backup file not found: $BACKUP_FILE"
    echo_info "Available backups:"
    ls -la "$BACKUP_DIR" 2>/dev/null || echo "  No backups found in $BACKUP_DIR"
    exit 1
fi

# List contents if requested
if [ "$LIST_ONLY" = true ]; then
    echo_info "Listing contents of: $FULL_BACKUP_PATH"
    if [[ "$FULL_BACKUP_PATH" == *.tar.gz ]]; then
        tar -tzf "$FULL_BACKUP_PATH"
    else
        ls -laR "$FULL_BACKUP_PATH"
    fi
    exit 0
fi

echo_warn "============================================"
echo_warn "  RESTORE OPERATION - DATA WILL BE OVERWRITTEN"
echo_warn "============================================"
echo ""
echo_info "Backup file: $FULL_BACKUP_PATH"
echo_info "Data directory: $DATA_DIR"
echo ""

read -p "Are you sure you want to continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo_info "Restore cancelled"
    exit 0
fi

# Stop containers
if [ "$STOP_CONTAINERS" = true ]; then
    echo_step "Stopping Docker containers..."
    cd "$PROJECT_DIR"
    
    if [ -f "docker-compose.local.yaml" ]; then
        $DOCKER_COMPOSE -f docker-compose.local.yaml down 2>/dev/null || true
    fi
    if [ -f "docker-compose.cloud.yaml" ]; then
        $DOCKER_COMPOSE -f docker-compose.cloud.yaml down 2>/dev/null || true
    fi
    if [ -f "docker-compose.yaml" ]; then
        $DOCKER_COMPOSE -f docker-compose.yaml down 2>/dev/null || true
    fi
    
    echo_info "Containers stopped"
fi

# Create backup of current data
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
PRE_RESTORE_BACKUP="${BACKUP_DIR}/pre-restore-${TIMESTAMP}"
echo_step "Creating pre-restore backup..."
mkdir -p "$PRE_RESTORE_BACKUP"
cp -r "$DATA_DIR" "$PRE_RESTORE_BACKUP"
echo_info "Pre-restore backup saved to: $PRE_RESTORE_BACKUP"

# Extract/restore backup
echo_step "Restoring data..."

if [ -d "$FULL_BACKUP_PATH" ]; then
    # Restore from directory
    if [ -n "$SPECIFIC_DIRS" ]; then
        IFS=',' read -ra DIRS <<< "$SPECIFIC_DIRS"
        for dir in "${DIRS[@]}"; do
            if [ -d "$FULL_BACKUP_PATH/data/$dir" ]; then
                rm -rf "${DATA_DIR}/${dir}"
                cp -r "$FULL_BACKUP_PATH/data/$dir" "${DATA_DIR}/"
                echo_info "Restored: $dir"
            else
                echo_warn "Directory not found in backup: $dir"
            fi
        done
    else
        rm -rf "$DATA_DIR"
        cp -r "$FULL_BACKUP_PATH/data" "$PROJECT_DIR/"
        echo_info "Restored all data"
    fi
elif [[ "$FULL_BACKUP_PATH" == *.tar.gz ]]; then
    # Extract tar.gz to temp directory
    TEMP_RESTORE=$(mktemp -d)
    tar -xzf "$FULL_BACKUP_PATH" -C "$TEMP_RESTORE"
    
    # Find the extracted directory
    EXTRACTED_DIR=$(ls -d "$TEMP_RESTORE"/letta-backup-*)
    
    if [ -n "$SPECIFIC_DIRS" ]; then
        IFS=',' read -ra DIRS <<< "$SPECIFIC_DIRS"
        for dir in "${DIRS[@]}"; do
            if [ -d "$EXTRACTED_DIR/data/$dir" ]; then
                rm -rf "${DATA_DIR}/${dir}"
                cp -r "$EXTRACTED_DIR/data/$dir" "${DATA_DIR}/"
                echo_info "Restored: $dir"
            else
                echo_warn "Directory not found in backup: $dir"
            fi
        done
    else
        rm -rf "$DATA_DIR"
        cp -r "$EXTRACTED_DIR/data" "$PROJECT_DIR/"
        echo_info "Restored all data"
    fi
    
    # Cleanup temp
    rm -rf "$TEMP_RESTORE"
fi

echo_info "Restore complete!"

# Start containers
if [ "$START_CONTAINERS" = true ]; then
    echo_step "Starting Docker containers..."
    cd "$PROJECT_DIR"
    
    if [ -f "docker-compose.local.yaml" ]; then
        $DOCKER_COMPOSE -f docker-compose.local.yaml up -d 2>/dev/null || true
    fi
    if [ -f "docker-compose.cloud.yaml" ]; then
        $DOCKER_COMPOSE -f docker-compose.cloud.yaml up -d 2>/dev/null || true
    fi
    if [ -f "docker-compose.yaml" ]; then
        $DOCKER_COMPOSE -f docker-compose.yaml up -d 2>/dev/null || true
    fi
    
    echo_info "Containers started"
    echo_info "Run 'docker-compose ps' to check status"
fi

echo_info "Restore operation completed!"
