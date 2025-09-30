#!/bin/bash

# One-command deployment script for GCP
# Usage: ./deploy.sh

set -e

# Configuration
INSTANCE_NAME="sd-gradio-app"
ZONE="us-central1-a"
MACHINE_TYPE="g2-standard-4"
BOOT_DISK_SIZE="100GB"
PROJECT_DIR="$HOME/sd-gradio-app"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI is not installed"
    echo "Install from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

print_header "Stable Diffusion Gradio Deployment"

# Step 1: Check if instance exists
print_status "Checking if instance exists..."
if gcloud compute instances describe $INSTANCE_NAME --zone=$ZONE &> /dev/null; then
    print_warning "Instance '$INSTANCE_NAME' already exists in zone '$ZONE'"
    read -p "Do you want to use the existing instance? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Deployment cancelled"
        exit 1
    fi
    INSTANCE_EXISTS=true
else
    INSTANCE_EXISTS=false
fi

# Step 2: Create instance if it doesn't exist
if [ "$INSTANCE_EXISTS" = false ]; then
    print_header "Creating GCP Instance"
    
    gcloud compute instances create $INSTANCE_NAME \
        --zone=$ZONE \
        --machine-type=$MACHINE_TYPE \
        --accelerator=type=nvidia-l4,count=1 \
        --image-family=ubuntu-2204-lts \
        --image-project=ubuntu-os-cloud \
        --boot-disk-size=$BOOT_DISK_SIZE \
        --maintenance-policy=TERMINATE \
        --tags=http-server,https-server
    
    print_status "Instance created successfully"
    print_warning "Waiting 30 seconds for instance to boot..."
    sleep 30
fi

# Step 3: Get external IP
print_status "Getting instance external IP..."
EXTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME \
    --zone=$ZONE \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
print_status "External IP: $EXTERNAL_IP"

# Step 4: Create firewall rule
print_status "Checking firewall rules..."
if gcloud compute firewall-rules describe allow-gradio &> /dev/null; then
    print_status "Firewall rule 'allow-gradio' already exists"
else
    print_status "Creating firewall rule..."
    gcloud compute firewall-rules create allow-gradio \
        --allow tcp:7860 \
        --source-ranges 0.0.0.0/0 \
        --description "Allow Gradio app access"
    print_status "Firewall rule created"
fi

# Step 5: Copy files to instance
print_header "Deploying Application Files"

print_status "Creating project directory on instance..."
gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command="mkdir -p $PROJECT_DIR"

print_status "Copying application files..."
gcloud compute scp --zone=$ZONE --recurse \
    app.py \
    download_models.py \
    requirements.txt \
    setup_gcp.sh \
    README.md \
    QUICKSTART.md \
    .gitignore \
    $INSTANCE_NAME:$PROJECT_DIR/

print_status "Making setup script executable..."
gcloud compute ssh $INSTANCE_NAME --zone=$ZONE \
    --command="chmod +x $PROJECT_DIR/setup_gcp.sh"

# Step 6: Run setup script
print_header "Running Setup Script"

print_status "Executing setup on remote instance..."
gcloud compute ssh $INSTANCE_NAME --zone=$ZONE \
    --command="cd $PROJECT_DIR && ./setup_gcp.sh"

# Step 7: Check if reboot is needed
print_status "Checking if reboot is needed..."
REBOOT_NEEDED=$(gcloud compute ssh $INSTANCE_NAME --zone=$ZONE \
    --command="[ -f /var/run/reboot-required ] && echo 'yes' || echo 'no'")

if [ "$REBOOT_NEEDED" = "yes" ]; then
    print_warning "System reboot required for driver installation"
    read -p "Reboot now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Rebooting instance..."
        gcloud compute instances stop $INSTANCE_NAME --zone=$ZONE
        sleep 10
        gcloud compute instances start $INSTANCE_NAME --zone=$ZONE
        print_warning "Waiting 60 seconds for instance to boot..."
        sleep 60
        
        print_status "Running setup script again..."
        gcloud compute ssh $INSTANCE_NAME --zone=$ZONE \
            --command="cd $PROJECT_DIR && ./setup_gcp.sh"
    fi
fi

# Step 8: Download model
print_header "Model Setup"

echo "Would you like to download a model now?"
echo "1) SD 1.5 (Recommended - ~4GB)"
echo "2) SDXL (~7GB)"
echo "3) Skip (download manually later)"
read -p "Select option (1-3): " model_option

case $model_option in
    1)
        print_status "Downloading SD 1.5 model..."
        gcloud compute ssh $INSTANCE_NAME --zone=$ZONE \
            --command="cd $PROJECT_DIR && source venv/bin/activate && python download_models.py sd15"
        ;;
    2)
        print_status "Downloading SDXL model..."
        gcloud compute ssh $INSTANCE_NAME --zone=$ZONE \
            --command="cd $PROJECT_DIR && source venv/bin/activate && python download_models.py sdxl"
        ;;
    *)
        print_warning "Skipping model download"
        ;;
esac

# Step 9: Start application
print_header "Starting Application"

read -p "Start the application now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Starting application in tmux session..."
    gcloud compute ssh $INSTANCE_NAME --zone=$ZONE \
        --command="cd $PROJECT_DIR && tmux new -d -s gradio 'source venv/bin/activate && python app.py'"
    
    print_status "Application started!"
    sleep 5
    
    # Check if it's running
    if gcloud compute ssh $INSTANCE_NAME --zone=$ZONE \
        --command="tmux has-session -t gradio 2>/dev/null"; then
        print_status "Application is running in tmux session 'gradio'"
    else
        print_warning "Failed to verify application status"
    fi
fi

# Final summary
print_header "Deployment Complete!"

echo -e "${GREEN}Your Stable Diffusion app is ready!${NC}\n"
echo "📍 Instance: $INSTANCE_NAME"
echo "🌐 External IP: $EXTERNAL_IP"
echo "🔗 Web Interface: http://$EXTERNAL_IP:7860"
echo ""
echo "Useful commands:"
echo "  • SSH into instance:"
echo "    gcloud compute ssh $INSTANCE_NAME --zone=$ZONE"
echo ""
echo "  • View application logs:"
echo "    gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command='tmux attach -t gradio'"
echo "    (Press Ctrl+B then D to detach)"
echo ""
echo "  • Stop instance (to save costs):"
echo "    gcloud compute instances stop $INSTANCE_NAME --zone=$ZONE"
echo ""
echo "  • Start instance:"
echo "    gcloud compute instances start $INSTANCE_NAME --zone=$ZONE"
echo ""
echo "  • Download more models:"
echo "    gcloud compute ssh $INSTANCE_NAME --zone=$ZONE"
echo "    cd $PROJECT_DIR && source venv/bin/activate"
echo "    python download_models.py --list"
echo ""
print_warning "Don't forget to stop the instance when not in use to avoid charges!"
echo ""