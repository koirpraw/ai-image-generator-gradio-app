#!/bin/bash

# Management script for SD Gradio App on GCP
# Usage: ./manage.sh [command]

set -e

# Configuration
INSTANCE_NAME="sd-gradio-app"
ZONE="us-central1-a"
PROJECT_DIR="$HOME/sd-gradio-app"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Show usage
show_usage() {
    echo "SD Gradio App Management Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  start       - Start the GCP instance"
    echo "  stop        - Stop the GCP instance"
    echo "  restart     - Restart the GCP instance"
    echo "  status      - Check instance and app status"
    echo "  ssh         - SSH into the instance"
    echo "  logs        - View application logs"
    echo "  app-start   - Start the Gradio app"
    echo "  app-stop    - Stop the Gradio app"
    echo "  app-restart - Restart the Gradio app"
    echo "  update      - Update application code from git"
    echo "  models      - List downloaded models"
    echo "  download    - Download a new model"
    echo "  ip          - Show external IP address"
    echo "  costs       - Estimate running costs"
    echo "  clean       - Clean up old files and cache"
    echo "  backup      - Backup models and config"
    echo "  delete      - Delete the GCP instance"
    echo ""
}

# Check if gcloud is configured
check_gcloud() {
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI is not installed"
        exit 1
    fi
}

# Start instance
start_instance() {
    print_status "Starting instance $INSTANCE_NAME..."
    gcloud compute instances start $INSTANCE_NAME --zone=$ZONE
    print_status "Instance started"
    sleep 10
    show_ip
}

# Stop instance
stop_instance() {
    print_warning "Stopping instance $INSTANCE_NAME..."
    gcloud compute instances stop $INSTANCE_NAME --zone=$ZONE
    print_status "Instance stopped"
}

# Restart instance
restart_instance() {
    print_warning "Restarting instance $INSTANCE_NAME..."
    stop_instance
    sleep 5
    start_instance
}

# Check status
check_status() {
    print_info "Checking instance status..."
    
    STATUS=$(gcloud compute instances describe $INSTANCE_NAME --zone=$ZONE --format='get(status)' 2>/dev/null || echo "NOT_FOUND")
    
    if [ "$STATUS" = "NOT_FOUND" ]; then
        print_error "Instance not found"
        return 1
    fi
    
    echo "Instance Status: $STATUS"
    
    if [ "$STATUS" = "RUNNING" ]; then
        EXTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
        echo "External IP: $EXTERNAL_IP"
        echo "Web Interface: http://$EXTERNAL_IP:7860"
        
        print_info "Checking app status..."
        APP_STATUS=$(gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command="tmux has-session -t gradio 2>/dev/null && echo 'RUNNING' || echo 'STOPPED'")
        echo "App Status: $APP_STATUS"
        
        if [ "$APP_STATUS" = "RUNNING" ]; then
            GPU_INFO=$(gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command="nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits" 2>/dev/null || echo "N/A")
            echo "GPU Usage: $GPU_INFO"
        fi
    fi
}

# SSH into instance
ssh_instance() {
    print_status "Connecting to $INSTANCE_NAME..."
    gcloud compute ssh $INSTANCE_NAME --zone=$ZONE
}

# View logs
view_logs() {
    print_status "Viewing application logs (Ctrl+C to exit)..."
    gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command="tmux attach -t gradio"
}

# Start app
start_app() {
    print_status "Starting Gradio app..."
    gcloud compute ssh $INSTANCE_NAME --zone=$ZONE \
        --command="cd $PROJECT_DIR && tmux new -d -s gradio 'source venv/bin/activate && python app.py'"
    print_status "App started in tmux session 'gradio'"
}

# Stop app
stop_app() {
    print_warning "Stopping Gradio app..."
    gcloud compute ssh $INSTANCE_NAME --zone=$ZONE \
        --command="tmux kill-session -t gradio 2>/dev/null || echo 'App not running'"
    print_status "App stopped"
}

# Restart app
restart_app() {
    stop_app
    sleep 2
    start_app
}

# Update code
update_code() {
    print_status "Updating application code..."
    gcloud compute ssh $INSTANCE_NAME --zone=$ZONE \
        --command="cd $PROJECT_DIR && git pull"
    print_warning "Restart the app to apply changes: $0 app-restart"
}

# List models
list_models() {
    print_status "Listing downloaded models..."
    gcloud compute ssh $INSTANCE_NAME --zone=$ZONE \
        --command="cd $PROJECT_DIR && source venv/bin/activate && python download_models.py --list"
}

# Download model
download_model() {
    echo "Available models:"
    echo "1) SD 1.5"
    echo "2) SDXL"
    echo "3) DreamShaper"
    echo "4) Realistic Vision"
    echo "5) Custom (enter repo ID)"
    read -p "Select model (1-5): " choice
    
    case $choice in
        1) MODEL="sd15" ;;
        2) MODEL="sdxl" ;;
        3) MODEL="dreamshaper" ;;
        4) MODEL="realistic-vision" ;;
        5) 
            read -p "Enter HuggingFace repo ID: " MODEL
            ;;
        *)
            print_error "Invalid choice"
            return 1
            ;;
    esac
    
    print_status "Downloading $MODEL..."
    gcloud compute ssh $INSTANCE_NAME --zone=$ZONE \
        --command="cd $PROJECT_DIR && source venv/bin/activate && python download_models.py $MODEL"
}

# Show IP
show_ip() {
    EXTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
    echo "External IP: $EXTERNAL_IP"
    echo "Web Interface: http://$EXTERNAL_IP:7860"
}

# Estimate costs
estimate_costs() {
    print_info "Cost Estimation (approximate)"
    echo ""
    echo "Instance Type: $MACHINE_TYPE (L4 GPU)"
    echo "Estimated hourly cost: ~\$0.70-1.00/hour"
    echo "Estimated daily cost (24h): ~\$17-24/day"
    echo "Estimated monthly cost (730h): ~\$511-730/month"
    echo ""
    echo "Storage (100GB): ~\$10/month"
    echo ""
    print_warning "Stop instance when not in use to minimize costs!"
    echo ""
    echo "View actual costs:"
    echo "https://console.cloud.google.com/billing"
}

# Clean up
clean_cache() {
    print_status "Cleaning cache and temporary files..."
    gcloud compute ssh $INSTANCE_NAME --zone=$ZONE \
        --command="cd $PROJECT_DIR && rm -rf __pycache__ *.log gradio_cached_examples && pip cache purge"
    print_status "Cleanup complete"
}

# Backup models
backup_models() {
    print_status "Creating backup of models directory..."
    BACKUP_NAME="models_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    gcloud compute ssh $INSTANCE_NAME --zone=$ZONE \
        --command="cd $PROJECT_DIR && tar -czf ~/$BACKUP_NAME models/"
    
    print_status "Downloading backup..."
    gcloud compute scp $INSTANCE_NAME:~/$BACKUP_NAME . --zone=$ZONE
    
    print_status "Backup saved as: $BACKUP_NAME"
    
    read -p "Delete remote backup? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        gcloud compute ssh $INSTANCE_NAME --zone=$ZONE \
            --command="rm ~/$BACKUP_NAME"
        print_status "Remote backup deleted"
    fi
}

# Delete instance
delete_instance() {
    print_warning "This will PERMANENTLY DELETE the instance and all data!"
    print_warning "Instance: $INSTANCE_NAME"
    echo ""
    read -p "Are you sure? Type 'DELETE' to confirm: " confirm
    
    if [ "$confirm" = "DELETE" ]; then
        print_warning "Deleting instance..."
        gcloud compute instances delete $INSTANCE_NAME --zone=$ZONE
        print_status "Instance deleted"
    else
        print_info "Deletion cancelled"
    fi
}

# Main script
check_gcloud

if [ $# -eq 0 ]; then
    show_usage
    exit 0
fi

case "$1" in
    start)
        start_instance
        ;;
    stop)
        stop_instance
        ;;
    restart)
        restart_instance
        ;;
    status)
        check_status
        ;;
    ssh)
        ssh_instance
        ;;
    logs)
        view_logs
        ;;
    app-start)
        start_app
        ;;
    app-stop)
        stop_app
        ;;
    app-restart)
        restart_app
        ;;
    update)
        update_code
        ;;
    models)
        list_models
        ;;
    download)
        download_model
        ;;
    ip)
        show_ip
        ;;
    costs)
        estimate_costs
        ;;
    clean)
        clean_cache
        ;;
    backup)
        backup_models
        ;;
    delete)
        delete_instance
        ;;
    *)
        print_error "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac