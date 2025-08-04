# Load pre-trained computer vision model (FIXED VERSION)
print("🤖 Loading Computer Vision Model")
print("=" * 40)

start_time = time.time()

# Use Google Vision Transformer (better PyTorch support than microsoft/resnet-50)
model_name = "google/vit-base-patch16-224"
print(f"📥 Downloading model: {model_name}")

# Load processor and model with FIXED parameters
processor = AutoImageProcessor.from_pretrained(model_name, use_fast=True)  # FIX: Added use_fast=True
model = AutoModelForImageClassification.from_pretrained(model_name)        # FIX: Using native PyTorch model

# Alternative: If you want to keep ResNet-50, use this instead:
# model_name = "microsoft/resnet-50"  
# processor = AutoImageProcessor.from_pretrained(model_name, use_fast=True)
# model = AutoModelForImageClassification.from_pretrained(model_name, from_tf=True)  # FIX: Added from_tf=True

# Move model to GPU if available  
model = model.to(device)
model.eval()

load_time = time.time() - start_time
print(f"✅ Model loaded in {load_time:.2f} seconds")
print(f"📊 Model parameters: {sum(p.numel() for p in model.parameters()):,}")
print(f"🔥 Running on: {device}")
print("🎯 Ready for satellite image classification!") 