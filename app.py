import gradio as gr
import torch
from diffusers import StableDiffusionPipeline, StableDiffusionXLPipeline, DPMSolverMultistepScheduler
from PIL import Image
import os
from pathlib import Path

class StableDiffusionGenerator:
    def __init__(self, model_path="./models", device="cuda"):
        self.model_path = Path(model_path)
        self.device = device if torch.cuda.is_available() else "cpu"
        self.pipeline = None
        self.current_model = None
        
    def load_model(self, model_name, model_type="SD1.5"):
        """Load a Stable Diffusion model"""
        try:
            model_full_path = self.model_path / model_name
            
            if not model_full_path.exists():
                return None, f"Model not found at {model_full_path}"
            
            # Clear previous model from memory
            if self.pipeline is not None:
                del self.pipeline
                torch.cuda.empty_cache()
            
            # Load appropriate pipeline based on model type
            if model_type == "SDXL":
                self.pipeline = StableDiffusionXLPipeline.from_pretrained(
                    str(model_full_path),
                    torch_dtype=torch.float16,
                    use_safetensors=True,
                    variant="fp16"
                )
            else:  # SD1.5 or SD2.1
                self.pipeline = StableDiffusionPipeline.from_pretrained(
                    str(model_full_path),
                    torch_dtype=torch.float16,
                    use_safetensors=True
                )
            
            # Use DPM++ 2M Karras scheduler for better quality
            self.pipeline.scheduler = DPMSolverMultistepScheduler.from_config(
                self.pipeline.scheduler.config,
                use_karras_sigmas=True
            )
            
            # Enable memory optimizations
            self.pipeline.enable_attention_slicing()
            self.pipeline.enable_vae_slicing()
            
            # Move to device
            self.pipeline = self.pipeline.to(self.device)
            self.current_model = model_name
            
            return self.pipeline, f"Successfully loaded {model_name}"
            
        except Exception as e:
            return None, f"Error loading model: {str(e)}"
    
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
            return None, "Please load a model first"
        
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
            info = f"Generated with seed: {seed}"
            
            return image, info
            
        except Exception as e:
            return None, f"Error generating image: {str(e)}"
    
    def get_available_models(self):
        """List available models in the models directory"""
        if not self.model_path.exists():
            return []
        
        models = [d.name for d in self.model_path.iterdir() if d.is_dir()]
        return models if models else ["No models found"]


# Initialize generator
generator = StableDiffusionGenerator()

# Get available models
available_models = generator.get_available_models()

def load_model_interface(model_name, model_type):
    """Interface function to load model"""
    _, message = generator.load_model(model_name, model_type)
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
with gr.Blocks(title="Stable Diffusion Image Generator", theme=gr.themes.Soft()) as demo:
    gr.Markdown("# 🎨 Stable Diffusion Image Generator")
    gr.Markdown("Generate images using Stable Diffusion models (SD1.5, SD2.1, SDXL)")
    
    with gr.Row():
        with gr.Column(scale=1):
            gr.Markdown("### Model Settings")
            model_dropdown = gr.Dropdown(
                choices=available_models,
                label="Select Model",
                value=available_models[0] if available_models and available_models[0] != "No models found" else None
            )
            model_type = gr.Radio(
                choices=["SD1.5", "SD2.1", "SDXL"],
                label="Model Type",
                value="SD1.5"
            )
            load_btn = gr.Button("Load Model", variant="primary")
            load_status = gr.Textbox(label="Status", interactive=False)
            
            gr.Markdown("### Generation Settings")
            
            prompt = gr.Textbox(
                label="Prompt",
                placeholder="a beautiful landscape with mountains and a lake, detailed, high quality",
                lines=3
            )
            
            negative_prompt = gr.Textbox(
                label="Negative Prompt",
                placeholder="blurry, low quality, distorted",
                lines=2
            )
            
            with gr.Row():
                steps = gr.Slider(
                    minimum=10,
                    maximum=100,
                    value=25,
                    step=1,
                    label="Steps"
                )
                guidance = gr.Slider(
                    minimum=1,
                    maximum=20,
                    value=7.5,
                    step=0.5,
                    label="Guidance Scale"
                )
            
            with gr.Row():
                width = gr.Slider(
                    minimum=256,
                    maximum=1024,
                    value=512,
                    step=64,
                    label="Width"
                )
                height = gr.Slider(
                    minimum=256,
                    maximum=1024,
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
            output_info = gr.Textbox(label="Generation Info", interactive=False)
    
    # Event handlers
    load_btn.click(
        fn=load_model_interface,
        inputs=[model_dropdown, model_type],
        outputs=[load_status]
    )
    
    generate_btn.click(
        fn=generate_image_interface,
        inputs=[prompt, negative_prompt, steps, guidance, width, height, seed],
        outputs=[output_image, output_info]
    )
    
    gr.Markdown("""
    ### Tips:
    - **SD1.5**: Best for 512x512 images, faster generation
    - **SDXL**: Best for 1024x1024 images, higher quality but slower
    - **Steps**: 20-30 steps usually give good results
    - **Guidance Scale**: 7-9 for most cases, higher for more prompt adherence
    - **Seed**: Use the same seed to reproduce images
    """)

if __name__ == "__main__":
    demo.launch(
        server_name="0.0.0.0",  # Allow external connections
        server_port=7860,
        share=False
    )