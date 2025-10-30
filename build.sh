#!/bin/bash

# Development Build Script for Scrotto
# Simple script for development builds and testing

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔨 Building Scrotto (Development)${NC}"
echo "=============================================="

# Check if Cargo.toml exists
if [[ ! -f "Cargo.toml" ]]; then
    echo -e "${RED}❌ Error: Cargo.toml not found. Run from project root.${NC}"
    exit 1
fi

# Build in release mode for better performance
echo -e "${BLUE}📦 Building in release mode...${NC}"
cargo build --release

# Check if build succeeded
if [[ -f "target/release/scrotto" ]]; then
    echo -e "${GREEN}✅ Build completed successfully!${NC}"
    echo ""
    echo "📍 Binary location: target/release/scrotto"
    echo ""
    echo "🎯 Quick test commands:"
    echo "  ./target/release/scrotto        # Area selection mode"
    echo "  ./target/release/scrotto --full # Full screen mode"
else
    echo -e "${RED}❌ Build failed - binary not found${NC}"
    exit 1
fi
