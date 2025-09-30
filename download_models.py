"""
Script to download Stable Diffusion models from HuggingFace
Run this script to download models to the ./models directory
"""

import os
from pathlib import Path
from huggingface_hub import snapshot_download
import argparse

# Popular Stable Diffusion models
MODELS = {
    "sd15": {
        "repo_id": "runwayml/stable-diffusion-v1-5",
        "name": "stable-diffusion-v1-5",
        "type": "SD1.5"
    },
    "sd21": {
        "repo_id": "stabilityai/stable-diffusion-2-1",
        "name": "stable-diffusion-2-1",
        "type": "SD2.1"
    },
    "sdxl": {
        "repo_id": "stabilityai/stable-diffusion-xl-base-1.0",
        "name": "stable-diffusion-xl-base-1.0",
        "type": "SDXL"
    },
    "dreamshaper": {
        "repo_id": "Lykon/DreamShaper",
        "name": "dreamshaper",
        "type": "SD1.5"
    },
    "realistic-vision": {
        "repo_id": "SG161222/Realistic_Vision_V5.1_noVAE",
        "name": "realistic-vision-v5",
        "type": "SD1.5"
    }
}

def download_model(model_key, models_dir="./models", token=None):
    """
    Download a Stable Diffusion model from HuggingFace
    
    Args:
        model_key: Key from MODELS dict or custom repo_id
        models_dir: Directory to save models
        token: HuggingFace token (optional, for private models)
    """
    models_path = Path(models_dir)
    models_path.mkdir(exist_ok=True)
    
    # Check if it's a predefined model or custom repo_id
    if model_key in MODELS:
        model_info = MODELS[model_key]
        repo_id = model_info["repo_id"]
        local_dir = models_path / model_info["name"]
        print(f"\n📦 Downloading {model_info['name']} ({model_info['type']})...")
    else:
        # Assume it's a custom repo_id
        repo_id = model_key
        model_name = repo_id.split("/")[-1]
        local_dir = models_path / model_name
        print(f"\n📦 Downloading {model_name} from {repo_id}...")
    
    if local_dir.exists():
        print(f"⚠️  Model already exists at {local_dir}")
        response = input("Do you want to re-download? (y/n): ")
        if response.lower() != 'y':
            print("Skipping download.")
            return
    
    try:
        print(f"Downloading to: {local_dir}")
        print("This may take a while depending on your internet connection...")
        
        snapshot_download(
            repo_id=repo_id,
            local_dir=str(local_dir),
            local_dir_use_symlinks=False,
            token=token,
            ignore_patterns=["*.msgpack", "*.h5", "*.ot"]  # Skip unnecessary files
        )
        
        print(f"✅ Successfully downloaded to {local_dir}")
        
    except Exception as e:
        print(f"❌ Error downloading model: {str(e)}")
        print("\nIf the model requires authentication, you may need to:")
        print("1. Create a HuggingFace account")
        print("2. Accept the model's license on HuggingFace")
        print("3. Generate an access token from https://huggingface.co/settings/tokens")
        print("4. Run this script with --token YOUR_TOKEN")

def list_models():
    """List all available predefined models"""
    print("\n📋 Available predefined models:")
    print("-" * 60)
    for key, info in MODELS.items():
        print(f"  {key:20s} - {info['name']:35s} ({info['type']})")
    print("-" * 60)
    print("\nYou can also use any HuggingFace repo_id directly")

def main():
    parser = argparse.ArgumentParser(
        description="Download Stable Diffusion models from HuggingFace"
    )
    parser.add_argument(
        "model",
        nargs="?",
        help="Model key (e.g., 'sd15', 'sdxl') or HuggingFace repo_id"
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="List available predefined models"
    )
    parser.add_argument(
        "--token",
        type=str,
        help="HuggingFace access token for private models"
    )
    parser.add_argument(
        "--models-dir",
        type=str,
        default="./models",
        help="Directory to save models (default: ./models)"
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Download all predefined models"
    )
    
    args = parser.parse_args()
    
    if args.list:
        list_models()
        return
    
    if args.all:
        print("🚀 Downloading all predefined models...")
        for model_key in MODELS.keys():
            download_model(model_key, args.models_dir, args.token)
        print("\n✨ All downloads completed!")
        return
    
    if not args.model:
        print("❌ Please specify a model to download")
        parser.print_help()
        print()
        list_models()
        return
    
    download_model(args.model, args.models_dir, args.token)

if __name__ == "__main__":
    main()