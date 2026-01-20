import requests
from bs4 import BeautifulSoup

# Fetch GMS login page
url = "http://202.129.240.148:8080/GIS/StudentLogin.jsp"
response = requests.get(url, timeout=30)

print("Status:", response.status_code)
print("Cookies:", response.cookies.get_dict())
print()

# Parse HTML
soup = BeautifulSoup(response.text, 'html.parser')

# Find all forms
forms = soup.find_all('form')
print(f"Found {len(forms)} form(s)")

for i, form in enumerate(forms):
    print(f"\n=== Form {i+1} ===")
    print(f"Action: {form.get('action', 'NO ACTION')}")
    print(f"Method: {form.get('method', 'NO METHOD')}")
    print(f"ID: {form.get('id', 'NO ID')}")
    print(f"Name: {form.get('name', 'NO NAME')}")
    
    # Find all inputs
    inputs = form.find_all('input')
    print(f"\nInputs ({len(inputs)}):")
    for inp in inputs:
        print(f"  - name={inp.get('name')}, type={inp.get('type')}, value={inp.get('value', '')[:20] if inp.get('value') else ''}")
    
    # Find all selects
    selects = form.find_all('select')
    print(f"\nSelects ({len(selects)}):")
    for sel in selects:
        print(f"  - name={sel.get('name')}")
        options = sel.find_all('option')
        for opt in options[:5]:
            print(f"    - value={opt.get('value')}, text={opt.text.strip()[:30]}")

# Also look for any JavaScript form submission
scripts = soup.find_all('script')
print(f"\n\nFound {len(scripts)} script(s)")
for script in scripts:
    if script.string and ('submit' in script.string.lower() or 'login' in script.string.lower()):
        print("Script with submit/login:", script.string[:200])
