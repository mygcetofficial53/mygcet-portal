import requests
from bs4 import BeautifulSoup
import hashlib

# Create session
session = requests.Session()

# Login first
login_url = "http://202.129.240.148:8080/GIS/StudentLogin.jsp"
session.get(login_url, timeout=30)

# Hash password and login
password = '25ITD004'
password_md5 = hashlib.md5(password.encode()).hexdigest()

action_url = "http://202.129.240.148:8080/GIS/LoginCheckStudent.do"
data = {
    'login_id': '12502080503001',
    'pass': password_md5,
    'login_type': 'Normal'
}
response = session.post(action_url, data=data, allow_redirects=True, timeout=30)
print("Login status: Success" if 'welcome' in response.text.lower() else "Login status: Failed")

# Now fetch Welcome page and analyze
print("\n=== WELCOME PAGE ===")
welcome_url = "http://202.129.240.148:8080/GIS/Student/WelCome.jsp"
response = session.get(welcome_url, timeout=30)
soup = BeautifulSoup(response.text, 'html.parser')

# Print the body text
body_text = soup.body.get_text() if soup.body else ""
print("Body text (first 1000 chars):")
print(body_text[:1000])

# Find all tables
tables = soup.find_all('table')
print(f"\nFound {len(tables)} tables on welcome page")

for i, table in enumerate(tables):
    print(f"\n--- Table {i+1} ---")
    rows = table.find_all('tr')
    for row in rows[:5]:  # First 5 rows
        cols = row.find_all(['td', 'th'])
        row_text = ' | '.join([col.get_text().strip()[:30] for col in cols])
        if row_text.strip():
            print(row_text)

# Now fetch Profile page
print("\n\n=== PROFILE PAGE ===")
profile_url = "http://202.129.240.148:8080/GIS/Student/Profile/ViewProfile.jsp"
response = session.get(profile_url, timeout=30)
soup = BeautifulSoup(response.text, 'html.parser')

body_text = soup.body.get_text() if soup.body else ""
print("Body text (first 1500 chars):")
print(body_text[:1500])

# Find all tables
tables = soup.find_all('table')
print(f"\nFound {len(tables)} tables on profile page")

for i, table in enumerate(tables):
    print(f"\n--- Table {i+1} ---")
    rows = table.find_all('tr')
    for row in rows[:15]:  # First 15 rows
        cols = row.find_all(['td', 'th'])
        row_text = ' | '.join([col.get_text().strip()[:40] for col in cols])
        if row_text.strip():
            print(row_text)
