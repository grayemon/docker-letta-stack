#!/bin/bash
# ============================================
# Docker Letta Stack - Log Viewer
# View and filter Docker logs
# ============================================

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
LINES=100
FOLLOW=false
TIMESTAMPS=false
SERVICE=""
LEVEL=""
COMPOSE_FILE=""

# Available services
SERVICES=("letta-server" "letta-bot" "letta-workspace" "postgres")

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Show usage
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --service <name>   Filter by service (letta-server, letta-bot, letta-workspace)"
    echo "  --lines <n>        Number of lines to show (default: 100)"
    echo "  --level <level>    Filter by level (error, warn, info, debug)"
    echo "  --timestamps       Show timestamps"
    echo "  -f, --follow       Follow log output (like tail -f)"
    echo "  -h, --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                          # Show last 100 lines from all services"
    echo "  $0 --service letta-server   # Show logs for letta-server only"
    echo "  $0 --level error            # Show only error messages"
    echo "  $0 --follow                 # Follow logs in real-time"
    echo "  $0 --service letta-bot --lines 50  # Last 50 lines from bot"
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --service)
            SERVICE="$2"
            shift 2
            ;;
        --lines)
            LINES="$2"
            shift 2
            ;;
        --level)
            LEVEL="$2"
            shift 2
            ;;
        --timestamps)
            TIMESTAMPS=true
            shift
            ;;
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Determine which compose file to use
determine_compose_file() {
    if [ -f "$PROJECT_DIR/docker-compose.local.yaml" ]; then
        COMPOSE_FILE="$PROJECT_DIR/docker-compose.local.yaml"
    elif [ -f "$PROJECT_DIR/docker-compose.cloud.yaml" ]; then
        COMPOSE_FILE="$PROJECT_DIR/docker-compose.cloud.yaml"
    elif [ -f "$PROJECT_DIR/docker-compose.yaml" ]; then
        COMPOSE_FILE="$PROJECT_DIR/docker-compose.yaml"
    fi
}

# Get container name for a service
get_container_name() {
    local service=$1
    local container=""
    
    # Try different prefixes
    for prefix in "" "letta-" "docker-letta-stack_"; do
        container="${prefix}${service}"
        if docker inspect "$container" > /dev/null 2>&1; then
            echo "$container"
            return 0
        fi
    done
    
    # Try with docker-compose
    if [ -n "$COMPOSE_FILE" ]; then
        container=$(docker-compose -f "$COMPOSE_FILE" ps -q "$service" 2>/dev/null)
        if [ -n "$container" ]; then
            docker inspect --format '{{.Name}}' "$container" 2>/dev/null | sed 's/^\///'
            return 0
        fi
    fi
    
    return 1
}

# Build docker logs command
build_log_command() {
    local cmd="docker logs"
    
    # Add tail
    cmd="$cmd --tail $LINES"
    
    # Add timestamps if requested
    if [ "$TIMESTAMPS" = true ]; then
        cmd="$cmd -t"
    fi
    
    # Add follow if requested
    if [ "$FOLLOW" = true ]; then
        cmd="$cmd -f"
    fi
    
    echo "$cmd"
}

# Main function
main() {
    determine_compose_file
    
    if [ -z "$COMPOSE_FILE" ]; then
        echo_error "No docker-compose file found"
        exit 1
    fi
    
    # Colorize logs function
    colorize_logs() {
        if command -v ccze &> /dev/null; then
            ccze -A
        else
            # Simple colorization
            sed -e "s/\(error\|ERROR\|fail\|FAIL\|critical\|CRITICAL\)/$(printf "\033[0;31m")\1$(printf "\033[0m")/g" \
                -e "s/\(warn\|WARN\|warning\|WARNING\)/$(printf "\033[0;33m")\1$(printf "\033[0m")/g" \
                -e "s/\(info\|INFO\)/$(printf "\033[0;32m")\1$(printf "\033[0m")/g" \
                -e "s/\(debug\|DEBUG\)/$(printf "\033[0;36m")\1$(printf "\033[0m")/g"
        fi
    }
    
    if [ -n "$SERVICE" ]; then
        # Check if service exists
        container=$(get_container_name "$SERVICE")
        if [ -z "$container" ]; then
            echo_error "Service '$SERVICE' not found or not running"
            echo_info "Available services: ${SERVICES[*]}"
            exit 1
        fi
        
        echo_info "Showing logs for: $SERVICE (container: $container)"
        
        # Build command
        cmd="docker logs --tail $LINES"
        [ "$TIMESTAMPS" = true ] && cmd="$cmd -t"
        [ "$FOLLOW" = true ] && cmd="$cmd -f"
        
        if [ -n "$LEVEL" ]; then
            # Run with grep filter
            eval "$cmd $container 2>&1" | grep -i "$LEVEL" | colorize_logs
        else
            eval "$cmd $container 2>&1" | colorize_logs
        fi
    else
        # Show all services
        if [ -n "$LEVEL" ]; then
            echo_info "Showing logs with level: $LEVEL"
            docker-compose -f "$COMPOSE_FILE" logs --tail="$LINES" 2>&1 | grep -i "$LEVEL" | colorize_logs
        else
            if [ "$FOLLOW" = true ]; then
                docker-compose -f "$COMPOSE_FILE" logs -f --tail="$LINES" 2>&1 | colorize_logs
            else
                docker-compose -f "$COMPOSE_FILE" logs --tail="$LINES" 2>&1 | colorize_logs
            fi
        fi
    fi
}

main
