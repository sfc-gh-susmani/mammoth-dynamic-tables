# Load pre-trained computer vision model (WORKING VERSION)
print("🤖 Loading Computer Vision Model")
print("=" * 40)

start_time = time.time()

# Use Facebook DeiT (Data-efficient Image Transformer) - has native PyTorch weights
model_name = "facebook/deit-base-patch16-224"
print(f"📥 Downloading model: {model_name}")

# Load processor and model with FIXED parameters
processor = AutoImageProcessor.from_pretrained(model_name, use_fast=True)
model = AutoModelForImageClassification.from_pretrained(model_name)  # Native PyTorch weights

# Move model to GPU if available  
model = model.to(device)
model.eval()

load_time = time.time() - start_time
print(f"✅ Model loaded in {load_time:.2f} seconds")
print(f"📊 Model parameters: {sum(p.numel() for p in model.parameters()):,}")
print(f"🔥 Running on: {device}")
print("🎯 Ready for satellite image classification!")

# Model info
print(f"🏷️  Model type: {model.__class__.__name__}")
print(f"📋 Labels available: {len(model.config.id2label)} categories") 