# Stable Diffusion Gradio App - Project Structure

Complete project structure and file descriptions for your Stable Diffusion image generation application.

## 📁 Complete File Structure

```
sd-gradio-app/
│
├── app.py                      # Main Gradio application (REQUIRED)
├── download_models.py          # Model download script (REQUIRED)
├── requirements.txt            # Python dependencies (REQUIRED)
│
├── setup_gcp.sh               # Automated GCP setup script
├── deploy.sh                  # One-command deployment script
├── manage.sh                  # Instance management script
│
├── README.md                  # Complete documentation
├── QUICKSTART.md              # 15-minute quick start guide
├── PROJECT_STRUCTURE.md       # This file
│
├── .gitignore                 # Git ignore file
├── config.yaml.example        # Configuration template
│
└── models/                    # Model storage directory (created automatically)
    ├── stable-diffusion-v1-5/
    ├── stable-diffusion-xl-base-1.0/
    └── [other models]/
```

## 📄 File Descriptions

### Core Application Files (Required)

#### `app.py`
- **Purpose**: Main Gradio web application
- **Features**:
  - Load multiple SD models (SD1.5, SD2.1, SDXL)
  - Generate images from text prompts
  - Adjustable generation parameters
  - Memory-optimized for L4 GPU
- **Usage**: `python app.py`

#### `download_models.py`
- **Purpose**: Download models from HuggingFace
- **Features**:
  - Predefined popular models
  - Custom repo ID support
  - Progress tracking
  - Resume capability
- **Usage**: 
  ```bash
  python download_models.py --list          # List models
  python download_models.py sd15            # Download SD 1.5
  python download_models.py sdxl --token XX # With auth token
  ```

#### `requirements.txt`
- **Purpose**: Python package dependencies
- **Key packages**:
  - torch (PyTorch with CUDA)
  - diffusers (Stable Diffusion pipelines)
  - gradio (Web interface)
  - transformers (Model support)
  - accelerate (Performance optimization)

### Setup & Deployment Scripts

#### `setup_gcp.sh`
- **Purpose**: Automated setup on GCP instance
- **What it does**:
  - Installs system dependencies
  - Installs NVIDIA drivers
  - Creates Python virtual environment
  - Installs PyTorch with CUDA
  - Installs application dependencies
  - Sets up systemd service (optional)
- **Usage**: `./setup_gcp.sh`

#### `deploy.sh`
- **Purpose**: One-command deployment from local machine
- **What it does**:
  - Creates GCP instance (if needed)
  - Configures firewall rules
  - Copies files to instance
  - Runs setup script
  - Downloads model
  - Starts application
- **Usage**: `./deploy.sh`
- **Prerequisites**: gcloud CLI installed locally

#### `manage.sh`
- **Purpose**: Manage running instance
- **Commands**:
  - `./manage.sh start` - Start instance
  - `./manage.sh stop` - Stop instance
  - `./manage.sh status` - Check status
  - `./manage.sh logs` - View logs
  - `./manage.sh app-restart` - Restart app
  - `./manage.sh download` - Download new model
  - See script for all commands
- **Usage**: `./manage.sh [command]`

### Documentation Files

#### `README.md`
- **Purpose**: Complete project documentation
- **Contents**:
  - Feature list
  - Installation instructions
  - GCP deployment guide
  - Usage guide
  - Troubleshooting
  - Model recommendations
  - Security considerations

#### `QUICKSTART.md`
- **Purpose**: Fast deployment guide
- **Target**: Get running in 15 minutes
- **Contents**:
  - Quick GCP setup
  - Essential commands
  - First image generation
  - Common issues

#### `PROJECT_STRUCTURE.md`
- **Purpose**: This file - project organization reference

### Configuration Files

#### `config.yaml.example`
- **Purpose**: Configuration template
- **Settings**:
  - Server settings (host, port)
  - Model defaults
  - Generation parameters
  - Performance options
  - Security settings
- **Usage**: Copy to `config.yaml` and customize

#### `.gitignore`
- **Purpose**: Exclude files from git
- **Excludes**:
  - Model files (too large)
  - Python cache
  - Virtual environment
  - Log files
  - Generated images (optional)

## 🚀 Deployment Workflows

### Workflow 1: Manual Local Development

1. Clone repository
2. Install dependencies: `pip install -r requirements.txt`
3. Download model: `python download_models.py sd15`
4. Run app: `python app.py`
5. Access at `http://localhost:7860`

### Workflow 2: Manual GCP Deployment

1. Create GCP instance with L4 GPU
2. SSH into instance
3. Clone repository
4. Run setup: `./setup_gcp.sh`
5. Download model: `python download_models.py sd15`
6. Start app: `python app.py`

### Workflow 3: Automated GCP Deployment (Recommended)

1. Install gcloud CLI locally
2. Clone repository locally
3. Make scripts executable: `chmod +x *.sh`
4. Run deployment: `./deploy.sh`
5. Access at `http://EXTERNAL_IP:7860`

### Workflow 4: Management Operations

```bash
# Start instance
./manage.sh start

# Check status
./manage.sh status

# Download new model
./manage.sh download

# View logs
./manage.sh logs

# Stop instance (save costs)
./manage.sh stop
```

## 🔧 Customization Options

### Adding Custom Models

1. **From HuggingFace**:
   ```bash
   python download_models.py username/model-name
   ```

2. **From Local Files**:
   - Create directory: `mkdir -p models/my-model`
   - Copy `.safetensors` file to `models/my-model/`
   - Update `app.py` model list if needed

### Modifying Generation Defaults

Edit `app.py`:
```python
# Change default parameters
steps = gr.Slider(value=30)  # Changed from 25
guidance = gr.Slider(value=8.0)  # Changed from 7.5
```

### Adding Authentication

Edit `app.py`:
```python
demo.launch(
    server_name="0.0.0.0",
    server_port=7860,
    auth=("username", "password")  # Add this line
)
```

### Enabling Model Caching

Add to `app.py`:
```python
from diffusers import DiffusionPipeline
DiffusionPipeline.enable_model_cpu_offload = True
```

## 📊 Resource Requirements

### Minimum Requirements
- **CPU**: 4 cores
- **RAM**: 16GB
- **GPU**: 8GB VRAM (for SD1.5)
- **Storage**: 50GB

### Recommended (GCP L4)
- **CPU**: 4 cores (g2-standard-4)
- **RAM**: 16GB
- **GPU**: NVIDIA L4 (24GB VRAM)
- **Storage**: 100GB

### Storage Breakdown
- System & dependencies: ~20GB
- SD 1.5 model: ~4GB
- SDXL model: ~7GB
- Additional models: 2-7GB each
- Generated images: Variable

## 🔐 Security Checklist

- [ ] Change default passwords in config
- [ ] Enable authentication for production
- [ ] Configure firewall rules appropriately
- [ ] Use HTTPS with SSL/TLS
- [ ] Implement rate limiting
- [ ] Regularly update dependencies
- [ ] Monitor access logs
- [ ] Use VPC for internal access
- [ ] Enable audit logging
- [ ] Implement backup strategy

## 🧪 Testing Checklist

Before deploying to production:
- [ ] Test model loading
- [ ] Test image generation with various prompts
- [ ] Test different image sizes
- [ ] Verify GPU utilization
- [ ] Test memory usage
- [ ] Check generation speed
- [ ] Test error handling
- [ ] Verify firewall access
- [ ] Test application restart
- [ ] Monitor for memory leaks

## 📝 Maintenance Tasks

### Daily
- Monitor GPU usage
- Check application logs
- Verify service is running

### Weekly
- Review generated images
- Check disk usage
- Update model list if needed

### Monthly
- Update dependencies
- Review and update documentation
- Backup models and configuration
- Review costs and optimize

### As Needed
- Download new models
- Update application code
- Scale instance if needed
- Implement new features

## 🆘 Quick Reference

### Essential Commands

```bash
# Start app
python app.py

# Download model
python download_models.py sd15

# Check GPU
nvidia-smi

# View logs
tail -f app.log

# Kill process
pkill -f app.py

# Restart in tmux
tmux new -s gradio
python app.py
# Ctrl+B, then D to detach
```

### GCP Commands

```bash
# Create instance
gcloud compute instances create sd-gradio-app --zone=us-central1-a

# SSH
gcloud compute ssh sd-gradio-app --zone=us-central1-a

# Stop/Start
gcloud compute instances stop sd-gradio-app --zone=us-central1-a
gcloud compute instances start sd-gradio-app --zone=us-central1-a

# Delete
gcloud compute instances delete sd-gradio-app --zone=us-central1-a
```

## 📚 Additional Resources

- Gradio Documentation: https://gradio.app/docs
- Diffusers Documentation: https://huggingface.co/docs/diffusers
- Stable Diffusion Models: https://huggingface.co/models?pipeline_tag=text-to-image
- CivitAI Models: https://civitai.com
- GCP Documentation: https://cloud.google.com/compute/docs

## 🤝 Contributing

To contribute to this project:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

Review individual model licenses:
- Stable Diffusion: CreativeML Open RAIL-M
- Check specific model pages on HuggingFace

---

Last Updated: 2025-09-30