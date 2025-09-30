# Quick Start Guide

This guide will get you up and running in 15 minutes on GCP with L4 GPU.

## Part 1: Create GCP Instance (5 minutes)

### Option A: Using GCP Console (Web UI)

1. Go to [GCP Console](https://console.cloud.google.com)
2. Navigate to **Compute Engine > VM Instances**
3. Click **Create Instance**
4. Configure:
   - **Name**: `ai-image-generator-gradio-app`
   - **Region**: Choose one with L4 GPU availability (e.g., `us-central1`)
   - **Machine configuration**: 
     - Series: `G2`
     - Machine type: `g2-standard-4` or `g2-standard-8`
   - **GPU**: 1 x NVIDIA L4
   - **Boot disk**: 
     - OS: `Ubuntu 22.04 LTS`
     - Size: `100 GB` (minimum)
   - **Firewall**: Check "Allow HTTP traffic"
5. Click **Create**

### Option B: Using gcloud CLI

```bash
gcloud compute instances create ai-image-generator-gradio-app \
    --zone=us-central1-a \
    --machine-type=g2-standard-4 \
    --accelerator=type=nvidia-l4,count=1 \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud \
    --boot-disk-size=100GB \
    --maintenance-policy=TERMINATE \
    --metadata=startup-script='#!/bin/bash
sudo apt-get update'
```

## Part 2: Setup Application (10 minutes)

### 1. SSH into Your Instance

```bash
gcloud compute ssh ai-image-generator-gradio-app --zone=us-central1-a
```

### 2. Clone Your Repository

```bash
# Clone from GitHub (replace with your repo URL)
git clone https://github.com/yourusername/ai-image-generator-gradio-app.git
cd ai-image-generator-gradio-app

# Or create manually and copy files
mkdir ai-image-generator-gradio-app
cd ai-image-generator-gradio-app
# Then upload app.py, download_models.py, requirements.txt, setup_gcp.sh
```

### 3. Run Setup Script

```bash
# Make script executable
chmod +x setup_gcp.sh

# Run setup
./setup_gcp.sh
```

The script will:
- Install system dependencies
- Install NVIDIA drivers (if needed)
- Setup Python virtual environment
- Install PyTorch with CUDA
- Install application dependencies

**Note**: If drivers are installed, you'll need to reboot and run the script again.

```bash
sudo reboot
# Wait 1-2 minutes, then SSH back in
gcloud compute ssh ai-image-generator-gradio-app --zone=us-central1-a
cd ai-image-generator-gradio-app
./setup_gcp.sh
```

### 4. Download a Model

```bash
# Activate virtual environment
source venv/bin/activate

# Download SD 1.5 (recommended for testing - ~4GB)
python download_models.py sd15

# Or download SDXL (~7GB)
python download_models.py sdxl

# Or list all available models
python download_models.py --list
```

### 5. Configure Firewall

```bash
gcloud compute firewall-rules create allow-gradio \
    --allow tcp:7860 \
    --source-ranges 0.0.0.0/0 \
    --description "Allow Gradio app access"
```

### 6. Run the Application

```bash
# Run directly (blocks terminal)
python app.py

# OR run in background with tmux (recommended)
tmux new -s gradio
python app.py
# Press Ctrl+B, then D to detach
# Reattach later with: tmux attach -t gradio

# OR run with nohup
nohup python app.py > app.log 2>&1 &
```

### 7. Access the Application

Get your instance's external IP:
```bash
gcloud compute instances describe ai-image-generator-gradio-app \
    --zone=us-central1-a \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
```

Open in browser:
```
http://YOUR_EXTERNAL_IP:7860
```

## Part 3: Generate Your First Image (2 minutes)

1. In the web interface, select your model from the dropdown
2. Choose model type (SD1.5 or SDXL)
3. Click "Load Model" (wait 30 seconds)
4. Enter a prompt: `"a beautiful landscape with mountains and lake, detailed, photorealistic"`
5. (Optional) Negative prompt: `"blurry, low quality"`
6. Click "Generate Image"

First generation takes ~10-15 seconds. Subsequent generations are faster!

## Troubleshooting

### "Model not found"
```bash
# Make sure you downloaded a model
cd ~/ai-image-generator-gradio-app
source venv/bin/activate
python download_models.py --list
python download_models.py sd15
```

### "Can't access the website"
```bash
# Check if firewall rule exists
gcloud compute firewall-rules list | grep gradio

# If not, create it
gcloud compute firewall-rules create allow-gradio \
    --allow tcp:7860 \
    --source-ranges 0.0.0.0/0
```

### "Out of memory"
- Try SD1.5 instead of SDXL
- Use smaller image dimensions (512x512)
- Check GPU memory: `nvidia-smi`

### "Application not running"
```bash
# Check if process is running
ps aux | grep python

# Check logs if using nohup
tail -f app.log

# Reattach to tmux session
tmux attach -t gradio
```

## Stop/Start Instance to Save Costs

```bash
# Stop instance (to save money when not in use)
gcloud compute instances stop ai-image-generator-gradio-app --zone=us-central1-a

# Start instance again
gcloud compute instances start ai-image-generator-gradio-app --zone=us-central1-a

# SSH back in
gcloud compute ssh ai-image-generator-gradio-app --zone=us-central1-a
cd ai-image-generator-gradio-app
source venv/bin/activate
python app.py
```

## Cost Estimates (as of 2024)

- **L4 GPU (g2-standard-4)**: ~$1.00/hour
- **Storage (100GB)**: ~$20/month
- **Network egress**: Variable

**Tip**: Stop the instance when not in use to save costs!

## Next Steps

- Try different models from the download script
- Experiment with generation parameters
- Check out [README.md](README.md) for advanced usage
- Download custom models from [CivitAI](https://civitai.com)

## Need Help?

- Check the main [README.md](README.md) for detailed documentation
- Review GCP logs: `gcloud compute instances get-serial-port-output ai-image-generator-gradio-app`
- Check application logs: `tail -f app.log`