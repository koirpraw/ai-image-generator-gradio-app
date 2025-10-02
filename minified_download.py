"""
Minified script to download only essential .safetensors checkpoint files
This approach downloads single checkpoint files instead of full model repositories
"""

import os
import requests
from pathlib import Path
from huggingface_hub import hf_hub_download
import argparse

# Popular Stable Diffusion checkpoint files (single .safetensors files)
CHECKPOINT_MODELS = {
    "sd15": {
        "repo_id": "runwayml/stable-diffusion-v1-5",
        "filename": "v1-5-pruned-emaonly.safetensors",
        "name": "sd15-v1-5-pruned-emaonly.safetensors",
        "type": "SD1.5"
    },
    "sd15-full": {
        "repo_id": "runwayml/stable-diffusion-v1-5", 
        "filename": "v1-5-pruned.safetensors",
        "name": "sd15-v1-5-pruned.safetensors",
        "type": "SD1.5"
    },
    "dreamshaper": {
        "repo_id": "Lykon/DreamShaper",
        "filename": "dreamshaper_8.safetensors",
        "name": "dreamshaper_8.safetensors",
        "type": "SD1.5"
    },
    "realistic-vision": {
        "repo_id": "SG161222/Realistic_Vision_V5.1_noVAE",
        "filename": "Realistic_Vision_V5.1_noVAE.safetensors",
        "name": "realistic_vision_v5.1.safetensors", 
        "type": "SD1.5"
    },
    "anything-v4": {
        "repo_id": "andite/anything-v4.0",
        "filename": "anything-v4.5-pruned.safetensors",
        "name": "anything-v4.5.safetensors",
        "type": "SD1.5"
    }
}

def download_checkpoint(model_key, checkpoints_dir="./checkpoints", token=None):
    """
    Download a single .safetensors checkpoint file
    
    Args:
        model_key: Key from CHECKPOINT_MODELS dict
        checkpoints_dir: Directory to save checkpoint files
        token: HuggingFace token (optional, for private models)
    """
    checkpoints_path = Path(checkpoints_dir)
    checkpoints_path.mkdir(exist_ok=True)
    
    if model_key not in CHECKPOINT_MODELS:
        print(f"❌ Unknown model key: {model_key}")
        print("Available models:", list(CHECKPOINT_MODELS.keys()))
        return
    
    model_info = CHECKPOINT_MODELS[model_key]
    repo_id = model_info["repo_id"]
    filename = model_info["filename"]
    local_filename = model_info["name"]
    model_type = model_info["type"]
    
    local_path = checkpoints_path / local_filename
    
    print(f"\n📦 Downloading {local_filename} ({model_type})...")
    print(f"From: {repo_id}")
    print(f"File: {filename}")
    
    if local_path.exists():
        print(f"⚠️  Checkpoint already exists at {local_path}")
        response = input("Do you want to re-download? (y/n): ")
        if response.lower() != 'y':
            print("Skipping download.")
            return
    
    try:
        print(f"Downloading to: {local_path}")
        print("This may take a while depending on your internet connection...")
        
        # Download single file
        downloaded_path = hf_hub_download(
            repo_id=repo_id,
            filename=filename,
            cache_dir=None,
            token=token,
            local_dir=str(checkpoints_path),
            local_dir_use_symlinks=False
        )
        
        # Rename to our preferred naming convention if needed
        if Path(downloaded_path).name != local_filename:
            Path(downloaded_path).rename(local_path)
            
        print(f"✅ Successfully downloaded {local_filename}")
        print(f"   File size: {local_path.stat().st_size / (1024**3):.2f} GB")
        
    except Exception as e:
        print(f"❌ Error downloading checkpoint: {str(e)}")
        print("\nIf the model requires authentication, you may need to:")
        print("1. Create a HuggingFace account")
        print("2. Accept the model's license on HuggingFace")
        print("3. Generate an access token from https://huggingface.co/settings/tokens")
        print("4. Run this script with --token YOUR_TOKEN")

def list_checkpoints():
    """List all available checkpoint models"""
    print("\n📋 Available checkpoint models:")
    print("-" * 80)
    for key, info in CHECKPOINT_MODELS.items():
        print(f"  {key:15s} - {info['name']:40s} ({info['type']})")
    print("-" * 80)
    print("\nThese are single .safetensors checkpoint files")
    print("Much smaller downloads compared to full model repositories")

def list_downloaded_checkpoints(checkpoints_dir="./checkpoints"):
    """List downloaded checkpoint files"""
    checkpoints_path = Path(checkpoints_dir)
    
    if not checkpoints_path.exists():
        print(f"\n📁 Checkpoints directory {checkpoints_dir} doesn't exist")
        return
    
    checkpoint_files = list(checkpoints_path.glob("*.safetensors"))
    
    if not checkpoint_files:
        print(f"\n📁 No checkpoint files found in {checkpoints_dir}")
        return
    
    print(f"\n📁 Downloaded checkpoint files in {checkpoints_dir}:")
    print("-" * 80)
    
    total_size = 0
    for file_path in sorted(checkpoint_files):
        size_gb = file_path.stat().st_size / (1024**3)
        total_size += size_gb
        print(f"  {file_path.name:50s} - {size_gb:.2f} GB")
    
    print("-" * 80)
    print(f"  Total size: {total_size:.2f} GB")

def main():
    parser = argparse.ArgumentParser(
        description="Download single .safetensors checkpoint files for Stable Diffusion"
    )
    parser.add_argument(
        "model",
        nargs="?",
        help="Model key (e.g., 'sd15', 'dreamshaper')"
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="List available checkpoint models"
    )
    parser.add_argument(
        "--downloaded",
        action="store_true", 
        help="List already downloaded checkpoint files"
    )
    parser.add_argument(
        "--token",
        type=str,
        help="HuggingFace access token for private models"
    )
    parser.add_argument(
        "--checkpoints-dir",
        type=str,
        default="./checkpoints",
        help="Directory to save checkpoint files (default: ./checkpoints)"
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Download all available checkpoint models"
    )
    
    args = parser.parse_args()
    
    if args.list:
        list_checkpoints()
        return
    
    if args.downloaded:
        list_downloaded_checkpoints(args.checkpoints_dir)
        return
    
    if args.all:
        print("🚀 Downloading all checkpoint models...")
        for model_key in CHECKPOINT_MODELS.keys():
            download_checkpoint(model_key, args.checkpoints_dir, args.token)
        print("\n✨ All downloads completed!")
        list_downloaded_checkpoints(args.checkpoints_dir)
        return
    
    if not args.model:
        print("❌ Please specify a model to download")
        parser.print_help()
        print()
        list_checkpoints()
        return
    
    download_checkpoint(args.model, args.checkpoints_dir, args.token)

if __name__ == "__main__":
    main()