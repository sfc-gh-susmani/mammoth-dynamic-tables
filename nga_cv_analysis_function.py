# Computer Vision Analysis Function (UPDATED FOR BOTH MODEL TYPES)
def analyze_satellite_image(s3_key, session, model, processor, device):
    """
    GPU-accelerated computer vision analysis of satellite imagery
    Supports both Hugging Face and torchvision models
    """
    try:
        # Get presigned URL for secure S3 access
        url_query = f"SELECT GET_PRESIGNED_URL('@s3_imagery_stage_direct', '{s3_key}', 3600) as url"
        url_result = session.sql(url_query).collect()
        
        if not url_result:
            return None, "Could not generate presigned URL"
            
        image_url = url_result[0]['URL']
        
        # Download and process image
        response = requests.get(image_url, timeout=30)
        image = Image.open(io.BytesIO(response.content)).convert('RGB')
        
        # Check if we're using Hugging Face or torchvision model
        is_huggingface = hasattr(model, 'config')
        
        # Preprocess image based on model type
        if is_huggingface:
            # Hugging Face model
            inputs = processor(image, return_tensors="pt").to(device)
        else:
            # Torchvision model
            if isinstance(processor, transforms.Compose):
                inputs = processor(image).unsqueeze(0).to(device)  # Add batch dimension
            else:
                # Fallback preprocessing
                transform = transforms.Compose([
                    transforms.Resize(224),
                    transforms.CenterCrop(224),
                    transforms.ToTensor(),
                    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
                ])
                inputs = transform(image).unsqueeze(0).to(device)
        
        # GPU-accelerated inference
        start_time = time.time()
        with torch.no_grad():
            if is_huggingface:
                outputs = model(**inputs)
                logits = outputs.logits
            else:
                logits = model(inputs)
            
            predictions = torch.nn.functional.softmax(logits, dim=-1)
        
        inference_time = time.time() - start_time
        
        # Get top 5 predictions
        top_predictions = torch.topk(predictions, 5)
        
        results = {
            'image': image,
            'predictions': [],
            'inference_time': inference_time,
            'device': str(device),
            'model_type': 'Hugging Face' if is_huggingface else 'Torchvision'
        }
        
        # Convert to readable format
        for score, idx in zip(top_predictions.values[0], top_predictions.indices[0]):
            if is_huggingface and hasattr(model, 'config') and hasattr(model.config, 'id2label'):
                label = model.config.id2label[idx.item()]
            else:
                # ImageNet class names for torchvision models
                label = f"Class_{idx.item()}"  # Simplified for demo
            
            confidence = score.item() * 100
            results['predictions'].append({
                'label': label,
                'confidence': confidence
            })
        
        return results, None
        
    except Exception as e:
        return None, f"Analysis error: {str(e)}"

print("🔬 Universal computer vision analysis function ready!")
print("⚡ Supports both Hugging Face and torchvision models")
print("🔒 Secure S3 access with presigned URLs") 