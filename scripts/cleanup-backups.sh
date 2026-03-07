#!/bin/bash
# ============================================
# Docker Letta Stack - Cleanup Backups Script
# Removes old backup files
# ============================================

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${PROJECT_DIR}/backups"

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

# Default values
RETENTION_DAYS=7
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --days)
            RETENTION_DAYS="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--days N] [--dry-run]"
            echo ""
            echo "Options:"
            echo "  --days N     Keep backups from the last N days (default: 7)"
            echo "  --dry-run    Show what would be deleted without actually deleting"
            echo ""
            echo "Examples:"
            echo "  $0                    # Remove backups older than 7 days"
            echo "  $0 --days 30          # Remove backups older than 30 days"
            echo "  $0 --dry-run          # Show what would be deleted"
            exit 0
            ;;
        *)
            echo_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo_info "No backups directory found at: $BACKUP_DIR"
    exit 0
fi

echo_info "Cleaning up backups older than $RETENTION_DAYS days"
echo ""

# Find backups to delete
OLD_BACKUPS=$(find "$BACKUP_DIR" \( -name "letta-backup-*.tar.gz" -o -type d -name "letta-backup-*" -o -type d -name "pre-restore-*" \) -mtime +${RETENTION_DAYS} 2>/dev/null)

if [ -z "$OLD_BACKUPS" ]; then
    echo_info "No old backups found to clean up"
    exit 0
fi

# Show what will be deleted
echo_warn "The following backups will be deleted:"
echo ""
echo "$OLD_BACKUPS" | while read -r backup; do
    size=$(du -sh "$backup" 2>/dev/null | cut -f1)
    echo "  - $(basename "$backup") ($size)"
done

# Count and size
count=$(echo "$OLD_BACKUPS" | grep -c . || true)
total_size=$(du -ch $OLD_BACKUPS 2>/dev/null | tail -1 | cut -f1)

echo ""
echo_info "Total: $count backup(s), $total_size"

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo_warn "DRY RUN - No files were actually deleted"
    exit 0
fi

# Confirm deletion
echo ""
read -p "Are you sure you want to delete these backups? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo_info "Cleanup cancelled"
    exit 0
fi

# Delete backups
echo ""
echo_info "Deleting old backups..."
echo "$OLD_BACKUPS" | while read -r backup; do
    rm -rf "$backup"
    echo_info "Deleted: $(basename "$backup")"
done

echo ""
echo_info "Cleanup complete!"
