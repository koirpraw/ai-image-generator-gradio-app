#!/bin/bash

# Setup script for Stable Diffusion Gradio App on GCP with L4 GPU
# This script automates the setup process on a fresh Ubuntu instance

set -e  # Exit on error

echo "=========================================="
echo "Stable Diffusion Gradio App Setup"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    print_error "Please do not run this script as root"
    exit 1
fi

# Step 1: Update system
print_status "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Step 2: Install system dependencies
print_status "Installing system dependencies..."
sudo apt-get install -y \
    python3-pip \
    python3-venv \
    git \
    wget \
    tmux \
    htop \
    build-essential

# Step 3: Check for NVIDIA GPU
print_status "Checking for NVIDIA GPU..."
if ! command -v nvidia-smi &> /dev/null; then
    print_warning "nvidia-smi not found. Installing NVIDIA drivers..."
    sudo apt-get install -y nvidia-driver-535
    print_warning "NVIDIA drivers installed. System reboot required!"
    print_warning "Please reboot and run this script again."
    exit 0
fi

print_status "GPU detected:"
nvidia-smi --query-gpu=gpu_name,memory.total --format=csv,noheader

# Step 4: Create project directory
PROJECT_DIR="$HOME/sd-gradio-app"
if [ -d "$PROJECT_DIR" ]; then
    print_warning "Project directory already exists at $PROJECT_DIR"
    read -p "Do you want to continue? This will not delete existing files. (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    print_status "Creating project directory at $PROJECT_DIR"
    mkdir -p "$PROJECT_DIR"
fi

cd "$PROJECT_DIR"

# Step 5: Setup Python virtual environment
print_status "Creating Python virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

print_status "Activating virtual environment..."
source venv/bin/activate

# Step 6: Install PyTorch with CUDA support
print_status "Installing PyTorch with CUDA support..."
pip install --upgrade pip
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Step 7: Install application dependencies
if [ -f "requirements.txt" ]; then
    print_status "Installing application dependencies from requirements.txt..."
    pip install -r requirements.txt
else
    print_status "requirements.txt not found. Installing core dependencies..."
    pip install diffusers transformers accelerate safetensors gradio pillow huggingface-hub
fi

# Step 8: Verify PyTorch CUDA
print_status "Verifying PyTorch CUDA installation..."
python3 << END
import torch
print(f"PyTorch version: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"CUDA version: {torch.version.cuda}")
    print(f"GPU: {torch.cuda.get_device_name(0)}")
    print(f"GPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.2f} GB")
END

# Step 9: Create models directory
print_status "Creating models directory..."
mkdir -p models

# Step 10: Setup firewall (if needed)
print_status "Checking firewall settings..."
if command -v gcloud &> /dev/null; then
    print_status "GCloud CLI detected. You may need to add firewall rules:"
    echo "Run: gcloud compute firewall-rules create allow-gradio --allow tcp:7860 --source-ranges 0.0.0.0/0"
else
    print_warning "GCloud CLI not found. Firewall rules must be configured manually in GCP Console."
fi

# Step 11: Create systemd service (optional)
print_status "Would you like to create a systemd service for auto-start?"
read -p "(y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "download_models.py" ]; then
        echo ""
        echo "Available models:"
        echo "1) SD 1.5 (Recommended for testing - ~4GB)"
        echo "2) SDXL (~7GB)"
        echo "3) DreamShaper (~2GB)"
        echo "4) Realistic Vision (~2GB)"
        echo "5) Skip for now"
        echo ""
        read -p "Select model (1-5): " model_choice
        
        case $model_choice in
            1)
                print_status "Downloading Stable Diffusion 1.5..."
                python download_models.py sd15
                ;;
            2)
                print_status "Downloading Stable Diffusion XL..."
                python download_models.py sdxl
                ;;
            3)
                print_status "Downloading DreamShaper..."
                python download_models.py dreamshaper
                ;;
            4)
                print_status "Downloading Realistic Vision..."
                python download_models.py realistic-vision
                ;;
            *)
                print_status "Skipping model download."
                ;;
        esac
    else
        print_warning "download_models.py not found. Please download models manually."
    fi
fi

# Final summary
echo ""
echo "=========================================="
print_status "Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Ensure you have downloaded at least one model:"
echo "   python download_models.py --list"
echo "   python download_models.py sd15"
echo ""
echo "2. Run the application:"
echo "   python app.py"
echo ""
echo "3. Access the web interface:"
echo "   http://$(curl -s ifconfig.me):7860"
echo "   or http://localhost:7860 (if accessing locally)"
echo ""
echo "4. (Optional) Run in background with tmux:"
echo "   tmux new -s gradio"
echo "   python app.py"
echo "   # Press Ctrl+B then D to detach"
echo ""
echo "5. (Optional) If you created systemd service:"
echo "   sudo systemctl start sd-gradio"
echo "   sudo systemctl status sd-gradio"
echo ""
print_warning "Remember to configure GCP firewall to allow port 7860!"
echo ""SERVICE_FILE="/etc/systemd/system/sd-gradio.service"
    
    sudo tee $SERVICE_FILE > /dev/null << EOF
[Unit]
Description=Stable Diffusion Gradio App
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$PROJECT_DIR
Environment="PATH=$PROJECT_DIR/venv/bin"
ExecStart=$PROJECT_DIR/venv/bin/python $PROJECT_DIR/app.py
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable sd-gradio.service
    print_status "Systemd service created. Start with: sudo systemctl start sd-gradio"
fi

# Step 12: Download a model (optional)
echo ""
print_status "Would you like to download a Stable Diffusion model now?"
print_warning "This will download several GB of data and may take 10-30 minutes."
read -p "(y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then