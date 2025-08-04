# Load pre-trained computer vision model (TF CONVERSION SOLUTION)
print("🤖 Loading Computer Vision Model")
print("=" * 40)

start_time = time.time()

# Use Facebook DeiT with TensorFlow conversion
model_name = "facebook/deit-base-patch16-224"
print(f"📥 Downloading model: {model_name}")
print("🔄 Converting from TensorFlow weights to PyTorch...")

try:
    # Load processor and model with TensorFlow conversion
    processor = AutoImageProcessor.from_pretrained(model_name, use_fast=True)
    model = AutoModelForImageClassification.from_pretrained(
        model_name, 
        from_tf=True,  # Convert from TensorFlow weights
        torch_dtype=torch.float32,  # Ensure float32 for compatibility
        low_cpu_mem_usage=True  # More efficient loading
    )
    
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
    
except Exception as e:
    print(f"❌ Error loading DeiT model: {e}")
    print("🔄 Falling back to torchvision ResNet50...")
    
    # Fallback: Use torchvision ResNet50 (guaranteed PyTorch)
    import torchvision.models as models
    from torchvision import transforms
    
    model = models.resnet50(pretrained=True)
    model = model.to(device)
    model.eval()
    
    # Create a simple processor for torchvision
    processor = transforms.Compose([
        transforms.Resize(224),
        transforms.CenterCrop(224),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    ])
    
    load_time = time.time() - start_time
    print(f"✅ Torchvision ResNet50 loaded in {load_time:.2f} seconds")
    print(f"📊 Model parameters: {sum(p.numel() for p in model.parameters()):,}")
    print(f"🔥 Running on: {device}")
    print("🎯 Ready for satellite image classification!") 