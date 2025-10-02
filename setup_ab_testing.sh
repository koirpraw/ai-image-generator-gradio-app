#!/bin/bash

# A/B Testing Setup Script
# This script helps you set up both versions for comparison

echo "🎯 Setting up A/B Testing Environment"
echo "======================================"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found. Please run:"
    echo "   python -m venv venv"
    echo "   source venv/bin/activate" 
    echo "   pip install -r requirements.txt"
    exit 1
fi

# Activate virtual environment
source venv/bin/activate

echo "✅ Virtual environment activated"

# Show current status
echo ""
echo "📊 Current Status:"
echo "=================="

# Check original models
echo "🅰️  Full Pipeline Models:"
if [ -d "models" ]; then
    du -sh models/* 2>/dev/null | head -5 || echo "   No models found"
else
    echo "   No models directory found"
fi

echo ""
echo "🅱️  Minified Checkpoints:"
if [ -d "checkpoints" ]; then
    du -sh checkpoints/* 2>/dev/null | head -5 || echo "   No checkpoints found"
else
    echo "   No checkpoints directory found"
fi

echo ""
echo "🚀 Quick Start Commands:"
echo "======================="
echo ""
echo "📥 Download models:"
echo "   # Full pipeline (12-15GB):"
echo "   python download_models.py sd15"
echo ""
echo "   # Minified checkpoint (4-6GB):"
echo "   python minified_download.py sd15"
echo ""
echo "🖥️  Run applications:"
echo "   # Full pipeline app (port 7860):"
echo "   python app.py"
echo ""
echo "   # Minified app (port 7861):"
echo "   python minified_app.py"
echo ""
echo "📊 Compare storage:"
echo "   # Check full models size:"
echo "   du -sh models/"
echo ""
echo "   # Check checkpoints size:"
echo "   du -sh checkpoints/"
echo ""
echo "🔍 Monitor performance:"
echo "   # GPU memory usage:"
echo "   watch -n 2 nvidia-smi"
echo ""
echo "   # Process memory:"
echo "   top -p \$(pgrep -f 'app.py\\|minified_app.py')"

echo ""
echo "💡 Testing Recommendations:"
echo "==========================="
echo "1. Start with minified version (faster download/setup)"
echo "2. Test generation quality and speed"
echo "3. Compare with full pipeline if needed"
echo "4. Monitor GPU memory usage during inference"
echo "5. Time model loading and switching operations"

echo ""
echo "🆘 Troubleshooting:"
echo "=================="
echo "• If modules missing: pip install -r requirements.txt"
echo "• If GPU issues: Check nvidia-smi and CUDA installation"
echo "• If models not loading: Check file permissions and paths"
echo "• If memory issues: Reduce batch size or image dimensions"