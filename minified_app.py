import gradio as gr
import torch
from diffusers import StableDiffusionPipeline, DPMSolverMultistepScheduler
from PIL import Image
import os
from pathlib import Path

class MinifiedStableDiffusionGenerator:
    def __init__(self, checkpoints_dir="./checkpoints", device="cuda"):
        self.checkpoints_dir = Path(checkpoints_dir)
        self.device = device if torch.cuda.is_available() else "cpu"
        self.pipeline = None
        self.current_checkpoint = None
        
        # Print device info
        if torch.cuda.is_available():
            print(f"🚀 Using GPU: {torch.cuda.get_device_name()}")
            print(f"   VRAM: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB")
        else:
            print("⚠️  Using CPU (will be slow)")
        
    def load_checkpoint(self, checkpoint_filename):
        """Load a Stable Diffusion model from a single .safetensors file"""
        try:
            checkpoint_path = self.checkpoints_dir / checkpoint_filename
            
            if not checkpoint_path.exists():
                return None, f"Checkpoint not found at {checkpoint_path}"
            
            # Clear previous model from memory
            if self.pipeline is not None:
                del self.pipeline
                torch.cuda.empty_cache()
            
            print(f"🔄 Loading checkpoint: {checkpoint_filename}")
            
            # Load from single file using diffusers
            self.pipeline = StableDiffusionPipeline.from_single_file(
                str(checkpoint_path),
                torch_dtype=torch.float16,
                use_safetensors=True,
                load_safety_checker=False,  # Skip safety checker for speed
                requires_safety_checker=False
            )
            
            # Use DPM++ 2M Karras scheduler for better quality
            self.pipeline.scheduler = DPMSolverMultistepScheduler.from_config(
                self.pipeline.scheduler.config,
                use_karras_sigmas=True,
                algorithm_type="dpmsolver++"
            )
            
            # Enable memory optimizations
            self.pipeline.enable_attention_slicing()
            self.pipeline.enable_vae_slicing()
            
            # Enable memory efficient attention if available
            try:
                self.pipeline.enable_xformers_memory_efficient_attention()
                print("✅ XFormers memory efficient attention enabled")
            except:
                print("⚠️  XFormers not available, using default attention")
            
            # Move to device
            self.pipeline = self.pipeline.to(self.device)
            self.current_checkpoint = checkpoint_filename
            
            return self.pipeline, f"✅ Successfully loaded {checkpoint_filename}"
            
        except Exception as e:
            return None, f"❌ Error loading checkpoint: {str(e)}"
    
    def generate_image(
        self,
        prompt,
        negative_prompt="",
        num_inference_steps=25,
        guidance_scale=7.5,
        width=512,
        height=512,
        seed=-1
    ):
        """Generate an image from text prompt"""
        if self.pipeline is None:
            return None, "Please load a checkpoint first"
        
        try:
            # Set random seed for reproducibility
            if seed == -1:
                seed = torch.randint(0, 2**32 - 1, (1,)).item()
            
            generator = torch.Generator(device=self.device).manual_seed(seed)
            
            # Generate image
            with torch.inference_mode():
                result = self.pipeline(
                    prompt=prompt,
                    negative_prompt=negative_prompt if negative_prompt else None,
                    num_inference_steps=num_inference_steps,
                    guidance_scale=guidance_scale,
                    width=width,
                    height=height,
                    generator=generator
                )
            
            image = result.images[0]
            info = f"Generated with seed: {seed}\nCheckpoint: {self.current_checkpoint}"
            
            return image, info
            
        except Exception as e:
            return None, f"❌ Error generating image: {str(e)}"
    
    def get_available_checkpoints(self):
        """List available checkpoint files in the checkpoints directory"""
        if not self.checkpoints_dir.exists():
            return []
        
        checkpoints = [f.name for f in self.checkpoints_dir.glob("*.safetensors")]
        return sorted(checkpoints) if checkpoints else ["No checkpoints found"]


# Initialize generator
generator = MinifiedStableDiffusionGenerator()

# Get available checkpoints
available_checkpoints = generator.get_available_checkpoints()

def load_checkpoint_interface(checkpoint_name):
    """Interface function to load checkpoint"""
    _, message = generator.load_checkpoint(checkpoint_name)
    return message

def generate_image_interface(prompt, negative_prompt, steps, guidance, width, height, seed):
    """Interface function to generate image"""
    image, info = generator.generate_image(
        prompt=prompt,
        negative_prompt=negative_prompt,
        num_inference_steps=steps,
        guidance_scale=guidance,
        width=width,
        height=height,
        seed=seed
    )
    return image, info

# Create Gradio interface
with gr.Blocks(title="Minified Stable Diffusion Generator", theme=gr.themes.Soft()) as demo:
    gr.Markdown("# 🎨 Minified Stable Diffusion Generator")
    gr.Markdown("**Single-file checkpoint approach** - Faster loading, smaller storage footprint")
    
    with gr.Row():
        with gr.Column(scale=1):
            gr.Markdown("### Checkpoint Settings")
            
            # Info about current approach
            gr.Markdown("""
            **🔹 This version uses single .safetensors checkpoint files**
            - Faster loading times
            - Smaller storage requirements  
            - Direct checkpoint loading with `from_single_file()`
            - No safety checker (faster inference)
            """)
            
            checkpoint_dropdown = gr.Dropdown(
                choices=available_checkpoints,
                label="Select Checkpoint",
                value=available_checkpoints[0] if available_checkpoints and available_checkpoints[0] != "No checkpoints found" else None,
                info="Single .safetensors checkpoint files"
            )
            
            load_btn = gr.Button("Load Checkpoint", variant="primary")
            load_status = gr.Textbox(label="Status", interactive=False)
            
            gr.Markdown("### Generation Settings")
            
            prompt = gr.Textbox(
                label="Prompt",
                placeholder="a beautiful landscape with mountains and a lake, detailed, high quality",
                lines=3
            )
            
            negative_prompt = gr.Textbox(
                label="Negative Prompt",
                placeholder="blurry, low quality, distorted, watermark",
                lines=2
            )
            
            with gr.Row():
                steps = gr.Slider(
                    minimum=10,
                    maximum=50,
                    value=25,
                    step=1,
                    label="Steps"
                )
                guidance = gr.Slider(
                    minimum=1,
                    maximum=15,
                    value=7.5,
                    step=0.5,
                    label="Guidance Scale"
                )
            
            with gr.Row():
                width = gr.Slider(
                    minimum=256,
                    maximum=768,
                    value=512,
                    step=64,
                    label="Width"
                )
                height = gr.Slider(
                    minimum=256,
                    maximum=768,
                    value=512,
                    step=64,
                    label="Height"
                )
            
            seed = gr.Number(
                label="Seed (-1 for random)",
                value=-1,
                precision=0
            )
            
            generate_btn = gr.Button("Generate Image", variant="primary", size="lg")
        
        with gr.Column(scale=1):
            gr.Markdown("### Generated Image")
            output_image = gr.Image(label="Output", type="pil")
            output_info = gr.Textbox(label="Generation Info", interactive=False, lines=3)
            
            # Add refresh button for checkpoints
            with gr.Row():
                refresh_btn = gr.Button("🔄 Refresh Checkpoints", size="sm")
    
    # Event handlers
    load_btn.click(
        fn=load_checkpoint_interface,
        inputs=[checkpoint_dropdown],
        outputs=[load_status]
    )
    
    generate_btn.click(
        fn=generate_image_interface,
        inputs=[prompt, negative_prompt, steps, guidance, width, height, seed],
        outputs=[output_image, output_info]
    )
    
    def refresh_checkpoints():
        """Refresh the checkpoint list"""
        updated_checkpoints = generator.get_available_checkpoints()
        return gr.Dropdown(choices=updated_checkpoints)
    
    refresh_btn.click(
        fn=refresh_checkpoints,
        outputs=[checkpoint_dropdown]
    )
    
    gr.Markdown("""
    ### 📊 Minified Version Benefits:
    - **Faster Loading**: Direct checkpoint loading (~10-30 seconds vs 1-3 minutes)
    - **Storage Efficient**: ~4-6GB per model vs ~12-15GB for full pipeline
    - **Simple Management**: Single file per model
    - **Quick Switching**: Faster model swapping during inference
    
    ### 🔧 To download checkpoints:
    ```bash
    python minified_download.py --list          # See available models
    python minified_download.py sd15            # Download SD 1.5
    python minified_download.py dreamshaper     # Download DreamShaper
    python minified_download.py --all           # Download all models
    ```
    
    ### ⚠️ Limitations:
    - No safety checker (content filtering disabled)
    - Limited component customization
    - Some advanced features may not be available
    """)

if __name__ == "__main__":
    demo.launch(
        server_name="0.0.0.0",  # Allow external connections
        server_port=7861,       # Different port from main app
        share=False
    )