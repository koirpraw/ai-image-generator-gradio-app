# Stable Diffusion Gradio Image Generator

A simple Gradio application for generating AI images using Stable Diffusion models (SD1.5, SD2.1, SDXL) on Google Cloud Platform with L4 GPU.

# App preview
![App Preview](app_preview.png)

## Features

- Support for multiple Stable Diffusion versions (SD1.5, SD2.1, SDXL)
- User-friendly Gradio interface
- Local model storage for faster generation
- Customizable generation parameters
- Memory-optimized for L4 GPU (48GB VRAM)
- Easy deployment on GCP

## Project Structure

```
sd-gradio-app/
├── app.py                 # Main Gradio application
├── download_models.py     # Script to download models from HuggingFace
├── requirements.txt       # Python dependencies
├── README.md             # This file
├── setup_gcp.sh          # GCP setup script
└── models/               # Directory for model files (created automatically)
```

## Local Setup

### Prerequisites

- Python 3.9 or higher
- CUDA-compatible GPU (recommended)
- At least 20GB free disk space

### Installation

1. Clone the repository:
```bash
git clone https://github.com/koirpraw/ai-image-generator-gradio-app.git
cd ai-image-generator-gradio-app
```

2. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Download models:

List available models:
```bash
python download_models.py --list
```

Download a specific model (e.g., Stable Diffusion 1.5):
```bash
python download_models.py sd15
```

Download SDXL:
```bash
python download_models.py sdxl
```

Download all models:
```bash
python download_models.py --all
```

For models requiring authentication:
```bash
python download_models.py sd15 --token YOUR_HUGGINGFACE_TOKEN
```

5. Run the application:
```bash
python app.py
```

Access the interface at `http://localhost:7860`

## GCP Deployment

### 1. Create GCP Instance

Create a Compute Engine instance with:
- Machine type: `g2-standard-4` or higher (with L4 GPU)
- Boot disk: Ubuntu 22.04 LTS (at least 100GB)
- GPU: 1x NVIDIA L4

### 2. SSH into the Instance

```bash
gcloud compute ssh your-instance-name --zone=your-zone
```

### 3. Install Dependencies

```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install Python and development tools
sudo apt-get install -y python3-pip python3-venv git

# Install NVIDIA drivers (if not already installed)
sudo apt-get install -y nvidia-driver-535

# Verify GPU
nvidia-smi
```

### 4. Setup Application

```bash
# Clone your repository
git clone <your-repo-url>
cd sd-gradio-app

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install PyTorch with CUDA support
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Install other dependencies
pip install -r requirements.txt

# Download models
python download_models.py sd15
# or
python download_models.py sdxl
```

### 5. Configure Firewall

Allow traffic on port 7860:

```bash
gcloud compute firewall-rules create allow-gradio \
    --allow tcp:7860 \
    --source-ranges 0.0.0.0/0 \
    --description "Allow Gradio app access"
```

### 6. Run the Application

For testing:
```bash
python app.py
```

For production (using tmux or screen):
```bash
# Install tmux
sudo apt-get install -y tmux

# Create a new tmux session
tmux new -s gradio

# Run the app
python app.py

# Detach from tmux: Ctrl+B then D
# Reattach later: tmux attach -t gradio
```

Or use nohup:
```bash
nohup python app.py > app.log 2>&1 &
```

### 7. Access the Application

Open your browser and navigate to:
```
http://YOUR_INSTANCE_EXTERNAL_IP:7860
```

## Usage Guide

### Loading a Model

1. Select a model from the dropdown menu
2. Choose the model type (SD1.5, SD2.1, or SDXL)
3. Click "Load Model" and wait for confirmation

### Generating Images

1. Enter your prompt (describe what you want to see)
2. (Optional) Enter negative prompt (what you don't want)
3. Adjust generation parameters:
   - **Steps**: 20-30 for good quality (more steps = slower but potentially better)
   - **Guidance Scale**: 7-9 recommended (higher = more faithful to prompt)
   - **Width/Height**: 512x512 for SD1.5, 1024x1024 for SDXL
   - **Seed**: Use -1 for random, or specific number for reproducibility
4. Click "Generate Image"

### Tips for Best Results

- **SD1.5**: Fast, good for 512x512 images
- **SDXL**: Slower but higher quality, best for 1024x1024
- Use descriptive prompts: "a beautiful sunset over mountains, detailed, photorealistic, 8k"
- Negative prompts help: "blurry, low quality, distorted, ugly"
- Experiment with different seeds for variations

## Model Recommendations

### Popular Models to Try

1. **Stable Diffusion 1.5**: General purpose, fast
   ```bash
   python download_models.py sd15
   ```

2. **Stable Diffusion XL**: High quality, detailed
   ```bash
   python download_models.py sdxl
   ```

3. **DreamShaper**: Great for artistic images
   ```bash
   python download_models.py dreamshaper
   ```

4. **Realistic Vision**: Excellent for photorealistic images
   ```bash
   python download_models.py realistic-vision
   ```

### Custom Models from CivitAI

To use models from CivitAI:

1. Download the model file (`.safetensors`)
2. Create a directory structure:
   ```bash
   mkdir -p models/custom-model-name
   ```
3. Place the model file in the directory and rename it to `model.safetensors`
4. You may need additional config files - check the model's documentation

## Troubleshooting

### Out of Memory Error

If you encounter OOM errors:
1. Reduce image dimensions
2. Use SD1.5 instead of SDXL
3. Reduce batch size (if implementing batch generation)

### Slow Generation

- L4 GPU should generate 512x512 images in ~5-10 seconds for SD1.5
- SDXL takes ~15-30 seconds for 1024x1024
- First generation is slower (model loading)

### Model Download Issues

If download fails:
- Check internet connection
- Some models require HuggingFace account and token
- Ensure sufficient disk space

### Port Already in Use

If port 7860 is busy:
```bash
# Find and kill the process
lsof -ti:7860 | xargs kill -9

# Or modify app.py to use different port
```

## Cost Optimization (GCP)

- Stop the instance when not in use: `gcloud compute instances stop your-instance-name`
- Use preemptible/spot instances for testing (much cheaper)
- Monitor usage with GCP cost management tools

## Security Considerations

- Don't expose the application directly to the internet for production use
- Consider setting up authentication
- Use Cloud Load Balancer with SSL/TLS for HTTPS
- Implement rate limiting for public deployments

## License

This project uses Stable Diffusion models which have their own licenses. Please review:
- Stable Diffusion 1.5: CreativeML Open RAIL-M
- Stable Diffusion XL: CreativeML Open RAIL++-M
- Check individual model licenses on HuggingFace or CivitAI

## Support

For issues or questions:
- Check the troubleshooting section
- Review model documentation on HuggingFace
- Check Gradio documentation: https://gradio.app/docs

## Credits

- Stable Diffusion by Stability AI
- Diffusers library by HuggingFace
- Gradio by Gradio team