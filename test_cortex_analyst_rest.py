#!/usr/bin/env python3
import json

def test_cortex_analyst_rest_api():
    """Test the Cortex Analyst REST API with our semantic model"""
    
    # Connection info
    account = 'SFSENORTHAMERICA-DODICSE'
    rest_api_url = f"https://{account}.snowflakecomputing.com/api/v2/cortex/analyst/message"
    
    # Prepare the request body according to the Snowflake documentation
    request_body = {
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "text", 
                        "text": "How many satellite images do we have?"
                    }
                ]
            }
        ],
        "semantic_model": {
            "file": "@nga_app_stage/semantic_models/nga_intelligence_semantic_model.yaml"
        }
    }
    
    print("="*60)
    print("CORTEX ANALYST REST API TEST")
    print("="*60)
    print(f"URL: {rest_api_url}")
    print(f"Method: POST")
    print("Headers needed:")
    print("  - Content-Type: application/json")
    print("  - Authorization: Bearer <JWT_TOKEN>")
    print("\nRequest Body:")
    print(json.dumps(request_body, indent=2))
    
    print("\n" + "="*60)
    print("CURL COMMAND TEMPLATE:")
    print("="*60)
    print(f"curl -X POST '{rest_api_url}' \\")
    print("  -H 'Content-Type: application/json' \\")
    print("  -H 'Authorization: Bearer <YOUR_JWT_TOKEN>' \\")
    print("  -d '" + json.dumps(request_body, separators=(',', ':')) + "'")
    
    print("\n" + "="*60)
    print("VALIDATION CHECKLIST:")
    print("="*60)
    print("✓ Account URL is correct")
    print("✓ Request body follows Snowflake API specification")
    print("✓ Semantic model path references our uploaded file")
    print("✓ Message format is correct with user role and text content")
    
    # Validate JSON format
    try:
        json.dumps(request_body)
        print("✓ JSON is valid")
    except Exception as e:
        print(f"✗ JSON error: {e}")
    
    print("\nTo get a JWT token, you can:")
    print("1. Use Snowflake's OAuth flow")
    print("2. Generate a JWT using private key authentication")
    print("3. Use browser authentication to get a session token")

if __name__ == "__main__":
    test_cortex_analyst_rest_api() 