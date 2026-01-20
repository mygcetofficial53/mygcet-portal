import requests

# Create session for cookie management
session = requests.Session()

# Step 1: Get login page to get cookies
login_url = "http://202.129.240.148:8080/GIS/StudentLogin.jsp"
response = session.get(login_url, timeout=30)
print("Step 1 - Get login page")
print("Status:", response.status_code)
print("Cookies:", session.cookies.get_dict())

# Step 2: Submit login form to the correct action URL
action_url = "http://202.129.240.148:8080/GIS/LoginCheckStudent.do"
data = {
    'login_id': '12502080503001',  # Replace with actual enrollment
    'pass': '25ITD004',  # Replace with actual password
    'login_type': 'Normal'
}

print("\nStep 2 - Submit login")
response = session.post(action_url, data=data, allow_redirects=True, timeout=30)
print("Status:", response.status_code)
print("Final URL:", response.url)
print("Cookies:", session.cookies.get_dict())

# Check response
body_lower = response.text.lower()
print("\nLogin indicators:")
print("- Has 'welcome':", 'welcome' in body_lower)
print("- Has 'logout':", 'logout' in body_lower)
print("- Has 'login_id' (still on login):", 'login_id' in body_lower)
print("- Has 'invalid':", 'invalid' in body_lower)

# Print first 500 chars
print("\nResponse preview:")
print(response.text[:500])
