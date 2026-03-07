#!/bin/bash
# ============================================
# Docker Letta Stack - List Backups Script
# Shows available backup files
# ============================================

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${PROJECT_DIR}/backups"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo_info "No backups directory found at: $BACKUP_DIR"
    echo_info "Run backup.sh to create your first backup"
    exit 0
fi

echo_info "Available backups in: $BACKUP_DIR"
echo ""

# List compressed backups
echo -e "${BLUE}Compressed backups:${NC}"
find "$BACKUP_DIR" -maxdepth 1 -name "letta-backup-*.tar.gz" -type f 2>/dev/null | sort -r | while read -r backup; do
    size=$(du -h "$backup" | cut -f1)
    date=$(stat -c %y "$backup" 2>/dev/null | cut -d' ' -f1 || stat -f "%Sm" -t "%Y-%m-%d" "$backup" 2>/dev/null)
    name=$(basename "$backup")
    echo "  $name"
    echo "    Size: $size | Date: $date"
done

# Check if there are no compressed backups
if [ -z "$(find "$BACKUP_DIR" -maxdepth 1 -name "letta-backup-*.tar.gz" -type f 2>/dev/null)" ]; then
    echo "  (none)"
fi

echo ""

# List uncompressed backup directories
echo -e "${BLUE}Uncompressed backups:${NC}"
find "$BACKUP_DIR" -maxdepth 1 -type d -name "letta-backup-*" 2>/dev/null | sort -r | while read -r backup; do
    size=$(du -sh "$backup" 2>/dev/null | cut -f1)
    date=$(stat -c %y "$backup" 2>/dev/null | cut -d' ' -f1 || stat -f "%Sm" -t "%Y-%m-%d" "$backup" 2>/dev/null)
    name=$(basename "$backup")
    echo "  $name"
    echo "    Size: $size | Date: $date"
done

# Check if there are no uncompressed backups
if [ -z "$(find "$BACKUP_DIR" -maxdepth 1 -type d -name "letta-backup-*" 2>/dev/null)" ]; then
    echo "  (none)"
fi

echo ""

# List pre-restore backups
echo -e "${YELLOW}Pre-restore backups:${NC}"
find "$BACKUP_DIR" -maxdepth 1 -type d -name "pre-restore-*" 2>/dev/null | sort -r | while read -r backup; do
    size=$(du -sh "$backup" 2>/dev/null | cut -f1)
    date=$(stat -c %y "$backup" 2>/dev/null | cut -d' ' -f1 || stat -f "%Sm" -t "%Y-%m-%d" "$backup" 2>/dev/null)
    name=$(basename "$backup")
    echo "  $name"
    echo "    Size: $size | Date: $date"
done

if [ -z "$(find "$BACKUP_DIR" -maxdepth 1 -type d -name "pre-restore-*" 2>/dev/null)" ]; then
    echo "  (none)"
fi

echo ""

# Show total backup count
total=$(find "$BACKUP_DIR" \( -name "letta-backup-*.tar.gz" -o -type d -name "letta-backup-*" -o -type d -name "pre-restore-*" \) 2>/dev/null | wc -l)
echo_info "Total backups: $total"
