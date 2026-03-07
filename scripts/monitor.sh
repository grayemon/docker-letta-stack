#!/bin/bash
# ============================================
# Docker Letta Stack - Monitor Script
# Health check and alerting for services
# ============================================

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output - check if terminal supports colors
if [[ -t 1 ]] && [[ -z "$NO_COLOR" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color
    USE_COLORS=true
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    NC=''
    USE_COLORS=false
fi

# Default values
VERBOSE=false
ALERT=false
CHECK_INTERVAL=1

# Services to check
SERVICES=("letta-server" "letta-bot" "letta-workspace")

echo_info() {
    if [[ "$USE_COLORS" == "true" ]]; then
        echo -e "${GREEN}[INFO]${NC} $1"
    else
        echo "[INFO] $1"
    fi
}

echo_warn() {
    if [[ "$USE_COLORS" == "true" ]]; then
        echo -e "${YELLOW}[WARN]${NC} $1"
    else
        echo "[WARN] $1"
    fi
}

echo_error() {
    if [[ "$USE_COLORS" == "true" ]]; then
        echo -e "${RED}[ERROR]${NC} $1"
    else
        echo "[ERROR] $1"
    fi
}

echo_success() {
    if [[ "$USE_COLORS" == "true" ]]; then
        echo -e "${GREEN}[OK]${NC} $1"
    else
        echo "[OK] $1"
    fi
}

# Show usage
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --verbose    Show detailed output including resource usage"
    echo "  --alert     Send alert on failure (requires Telegram bot configured)"
    echo "  --watch     Continuous monitoring (Ctrl+C to stop)"
    echo "  --service   Check specific service only"
    echo "  -h, --help  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Check all services once"
    echo "  $0 --verbose          # Detailed output"
    echo "  $0 --watch            # Continuous monitoring"
    echo "  $0 --service letta-server  # Check specific service"
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE=true
            shift
            ;;
        --alert)
            ALERT=true
            shift
            ;;
        --watch)
            WATCH=true
            shift
            ;;
        --service)
            SERVICES=("$2")
            shift 2
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

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo_error "Docker is not running or not accessible"
        exit 1
    fi
}

# Get container status
get_container_status() {
    local container=$1
    docker inspect -f '{{.State.Status}}' "$container" 2>/dev/null || echo "not found"
}

# Get container health
get_container_health() {
    local container=$1
    docker inspect -f '{{.State.Health.Status}}' "$container" 2>/dev/null || echo "none"
}

# Get container resource usage
get_container_stats() {
    local container=$1
    docker stats --no-stream --format "{{.CPUPerc}}|{{.MemUsage}}" "$container" 2>/dev/null || echo "N/A|N/A"
}

# Check service health
check_service() {
    local service=$1
    local compose_file=""
    
    # Determine which compose file to use
    if [ -f "$PROJECT_DIR/docker-compose.local.yaml" ]; then
        compose_file="$PROJECT_DIR/docker-compose.local.yaml"
    elif [ -f "$PROJECT_DIR/docker-compose.cloud.yaml" ]; then
        compose_file="$PROJECT_DIR/docker-compose.cloud.yaml"
    elif [ -f "$PROJECT_DIR/docker-compose.yaml" ]; then
        compose_file="$PROJECT_DIR/docker-compose.yaml"
    fi
    
    # Check if service exists in compose file
    if [ -n "$compose_file" ]; then
        local container_name=$(docker-compose -f "$compose_file" ps -q "$service" 2>/dev/null)
        if [ -z "$container_name" ]; then
            echo -e "${YELLOW}[SKIP]${NC} $service (not running)"
            return 2
        fi
    fi
    
    # Get container name (handle different compose file prefixes)
    local container=""
    for prefix in "" "letta-" "docker-letta-stack_"; do
        container="${prefix}${service}"
        if docker inspect "$container" > /dev/null 2>&1; then
            break
        fi
        container=""
    done
    
    if [ -z "$container" ]; then
        # Try with docker-compose
        if [ -n "$compose_file" ]; then
            container=$(docker-compose -f "$compose_file" ps -q "$service" 2>/dev/null)
            if [ -n "$container" ]; then
                container=$(docker inspect --format '{{.Name}}' "$container" 2>/dev/null | sed 's/^\///')
            fi
        fi
    fi
    
    if [ -z "$container" ]; then
        echo_warn "$service: Container not found"
        return 1
    fi
    
    # Check status
    local status=$(get_container_status "$container")
    local health=$(get_container_health "$container")
    
    if [ "$status" == "running" ]; then
        if [ "$health" == "healthy" ] || [ "$health" == "none" ]; then
            echo -e "${GREEN}[OK]${NC} $service"
            
            if [ "$VERBOSE" = true ]; then
                local stats=$(get_container_stats "$container")
                local cpu=$(echo "$stats" | cut -d'|' -f1)
                local mem=$(echo "$stats" | cut -d'|' -f2)
                echo -e "       CPU: $cpu | Memory: $mem"
            fi
            return 0
        elif [ "$health" == "unhealthy" ]; then
            echo -e "${RED}[FAIL]${NC} $service (unhealthy)"
            return 1
        else
            echo -e "${YELLOW}[WARN]${NC} $service (starting)"
            return 2
        fi
    else
        echo -e "${RED}[FAIL]${NC} $service (not running: $status)"
        return 1
    fi
}

# Check Letta server health endpoint
check_letta_api() {
    local port=8283
    if curl -s -f -o /dev/null "http://localhost:${port}/v1/health" 2>/dev/null; then
        echo -e "${GREEN}[OK]${NC} Letta API (localhost:${port})"
        return 0
    else
        echo -e "${RED}[FAIL]${NC} Letta API (localhost:${port})"
        return 1
    fi
}

# Send alert (Telegram)
send_alert() {
    local message="$1"
    
    # Check if Telegram bot is configured
    if [ -f "$PROJECT_DIR/.env" ]; then
        source "$PROJECT_DIR/.env"
        
        if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
            curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
                -d "chat_id=$TELEGRAM_CHAT_ID" \
                -d "text=$message" > /dev/null 2>&1
            echo_info "Alert sent to Telegram"
        fi
    fi
}

# Main monitoring function
run_monitoring() {
    local failed=0
    local total=0
    
    echo_info "Checking services..."
    echo ""
    
    # Show timestamp
    echo -e "${CYAN}Time: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo ""
    
    # Check each service
    for service in "${SERVICES[@]}"; do
        ((total++))
        check_service "$service"
        local result=$?
        if [ $result -eq 1 ]; then
            ((failed++))
        fi
    done
    
    # Check Letta API if letta-server is in the list
    if [[ " ${SERVICES[@]} " =~ "letta-server" ]]; then
        ((total++))
        check_letta_api
        local api_result=$?
        if [ $api_result -eq 1 ]; then
            ((failed++))
        fi
    fi
    
    echo ""
    
    # Summary
    if [ $failed -eq 0 ]; then
        echo_success "All services healthy ($total/$total)"
        return 0
    else
        echo_error "Some services unhealthy ($((total - failed))/$total)"
        
        if [ "$ALERT" = true ]; then
            send_alert "⚠️ Docker Letta Stack: $failed service(s) unhealthy!"
        fi
        return 1
    fi
}

# Initial check
check_docker

# Run once or continuously
if [ "$WATCH" = true ]; then
    echo_info "Starting continuous monitoring (Ctrl+C to stop)..."
    while true; do
        clear
        run_monitoring
        echo ""
        echo_info "Next check in ${CHECK_INTERVAL}s..."
        sleep "$CHECK_INTERVAL"
    done
else
    run_monitoring
fi
