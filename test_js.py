import requests
from bs4 import BeautifulSoup

# Create session for cookie management
session = requests.Session()

# Step 1: Get login page
login_url = "http://202.129.240.148:8080/GIS/StudentLogin.jsp"
response = session.get(login_url, timeout=30)
soup = BeautifulSoup(response.text, 'html.parser')

# Check for any JavaScript that might modify the data
scripts = soup.find_all('script')
print("=== JavaScript Analysis ===")
for script in scripts:
    if script.string:
        text = script.string.lower()
        if 'md5' in text or 'encrypt' in text or 'submit' in text or 'check' in text:
            print("\n--- Script with relevant keywords ---")
            print(script.string[:1000])

# Try submitting with looking at what the form actually does
form = soup.find('form')
print("\n\n=== Form Details ===")
print(form)
