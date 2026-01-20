import requests
import hashlib

# Create session for cookie management
session = requests.Session()

# Step 1: Get login page to get cookies
login_url = "http://202.129.240.148:8080/GIS/StudentLogin.jsp"
response = session.get(login_url, timeout=30)
print("Step 1 - Got login page, cookies:", session.cookies.get_dict())

# Step 2: Hash the password with MD5
password = '25ITD004'
password_md5 = hashlib.md5(password.encode()).hexdigest()
print(f"Password MD5: {password_md5}")

# Step 3: Submit login form with MD5 hashed password
action_url = "http://202.129.240.148:8080/GIS/LoginCheckStudent.do"
data = {
    'login_id': '12502080503001',
    'pass': password_md5,  # MD5 hashed password
    'login_type': 'Normal'
}

print("\nStep 2 - Submit login with MD5 password")
response = session.post(action_url, data=data, allow_redirects=True, timeout=30)
print("Status:", response.status_code)
print("Final URL:", response.url)

# Check response
body_lower = response.text.lower()
print("\nLogin indicators:")
print("- Has 'welcome':", 'welcome' in body_lower)
print("- Has 'logout':", 'logout' in body_lower)
print("- Has 'login_id' (still on login):", 'login_id' in body_lower)
print("- Has 'invalid':", 'invalid' in body_lower)

if 'welcome' in body_lower or 'logout' in body_lower:
    print("\n✓ LOGIN SUCCESSFUL!")
    print("\nResponse preview:")
    print(response.text[:1000])
else:
    print("\n✗ Login failed")
    print("\nResponse preview:")
    print(response.text[:500])
