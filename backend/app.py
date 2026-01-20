from flask import Flask, request, jsonify
from flask_cors import CORS
import uuid
import time
import requests
import base64
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import NoSuchElementException, TimeoutException
import threading
import re

app = Flask(__name__)
CORS(app)

# Store sessions
sessions = {}

# GMS Portal URLs
GMS_BASE_URL = 'http://202.129.240.148:8080/GIS'
GMS_LOGIN_URL = f'{GMS_BASE_URL}/StudentLogin.jsp'

# Pages after login (from user's screenshot)
GMS_WELCOME_URL = f'{GMS_BASE_URL}/Student/WelCome.jsp'
GMS_ATTENDANCE_URL = f'{GMS_BASE_URL}/Student/ViewMyAttendance.jsp'
GMS_MATERIALS_URL = f'{GMS_BASE_URL}/Student/ViewUploadMaterialNew.jsp'
GMS_QUIZ_URL = f'{GMS_BASE_URL}/Student/Quiz_Result.jsp'
GMS_LIBRARY_URL = f'{GMS_BASE_URL}/Library/Library_Book_Issued.jsp'  # Library page
GMS_CALENDAR_URL = f'{GMS_BASE_URL}/Student/Academic_Calender.jsp'  # Academic Calendar
GMS_MID_SEM_URL = f'{GMS_BASE_URL}/Stu_ViewMidSemMarks.jsp'
GMS_REMEDIAL_URL = f'{GMS_BASE_URL}/Stu_ViewRemedialMarks.jsp'
GMS_REGISTRATION_URL = f'{GMS_BASE_URL}/ViewRegistration.jsp'
GMS_PROFILE_URL = f'{GMS_BASE_URL}/Student/Profile/ViewProfile.jsp'
GMS_CHANGE_PASSWORD_URL = f'{GMS_BASE_URL}/Student/Profile/ChangePassword.jsp'

def create_driver():
    """Create Chrome WebDriver with optimized settings"""
    chrome_options = Options()
    chrome_options.add_argument('--headless')
    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--disable-dev-shm-usage')
    chrome_options.add_argument('--disable-gpu')
    chrome_options.add_argument('--window-size=1920,1080')
    chrome_options.add_argument('--disable-extensions')
    chrome_options.add_argument('--disable-infobars')
    chrome_options.add_argument('--disable-notifications')
    chrome_options.add_experimental_option('excludeSwitches', ['enable-logging'])
    
    driver = webdriver.Chrome(options=chrome_options)
    driver.set_page_load_timeout(60)
    driver.implicitly_wait(5)
    return driver

@app.route('/api/captcha', methods=['GET'])
def get_captcha():
    """Fetch captcha image from GMS portal if present"""
    session_id = str(uuid.uuid4())
    
    try:
        driver = create_driver()
        sessions[session_id] = {'driver': driver, 'created': time.time(), 'logged_in': False}
        
        driver.get(GMS_LOGIN_URL)
        time.sleep(2)
        
        # Check for captcha image
        captcha_image = None
        try:
            # Look for captcha image element
            captcha_elements = driver.find_elements(By.CSS_SELECTOR, 'img[src*="captcha"], img[src*="Captcha"], img[id*="captcha"]')
            if captcha_elements:
                captcha_img = captcha_elements[0]
                # Get image as base64
                captcha_src = captcha_img.get_attribute('src')
                if captcha_src:
                    if captcha_src.startswith('data:'):
                        captcha_image = captcha_src
                    else:
                        # Take screenshot of captcha element
                        captcha_image = 'data:image/png;base64,' + base64.b64encode(captcha_img.screenshot_as_png).decode()
        except:
            pass
        
        return jsonify({
            'success': True,
            'session_id': session_id,
            'captcha_image': captcha_image,
            'has_captcha': captcha_image is not None
        })
        
    except Exception as e:
        if session_id in sessions:
            try:
                sessions[session_id]['driver'].quit()
            except:
                pass
            del sessions[session_id]
        
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/api/login', methods=['POST'])
def login():
    """Login to GMS portal using Selenium"""
    data = request.json
    username = data.get('username')
    password = data.get('password')
    captcha = data.get('captcha', '')
    session_id = data.get('session_id')
    
    if not all([username, password]):
        return jsonify({'success': False, 'message': 'Missing credentials'}), 400
    
    try:
        # Get existing driver or create new one
        if session_id and session_id in sessions:
            driver = sessions[session_id]['driver']
        else:
            driver = create_driver()
            session_id = str(uuid.uuid4())
            sessions[session_id] = {'driver': driver, 'created': time.time(), 'logged_in': False}
            driver.get(GMS_LOGIN_URL)
            time.sleep(2)
        
        # Fill login form
        try:
            # Fill login ID (enrollment number)
            login_field = driver.find_element(By.NAME, 'login_id')
            login_field.clear()
            login_field.send_keys(username)
            
            # Fill password
            password_field = driver.find_element(By.NAME, 'pass')
            password_field.clear()
            password_field.send_keys(password)
            
            # Fill captcha if present
            if captcha:
                try:
                    captcha_field = driver.find_element(By.NAME, 'captcha')
                    captcha_field.clear()
                    captcha_field.send_keys(captcha)
                except NoSuchElementException:
                    pass
            
            # Click submit
            submit_btn = driver.find_element(By.CSS_SELECTOR, 'input[type="submit"]')
            submit_btn.click()
            
            time.sleep(3)
            
        except NoSuchElementException as e:
            return jsonify({'success': False, 'message': f'Login form error: {e}'}), 500
        
        # Check login result
        current_url = driver.current_url.lower()
        page_text = driver.find_element(By.TAG_NAME, 'body').text.lower()
        
        # Check for error messages
        if 'invalid' in page_text or 'wrong' in page_text or 'incorrect' in page_text:
            return jsonify({
                'success': False,
                'message': 'Invalid enrollment number or password'
            }), 401
        
        if 'captcha' in page_text and 'wrong' in page_text:
            return jsonify({
                'success': False,
                'message': 'Invalid captcha. Please try again.'
            }), 401
        
        # Login successful if redirected to welcome or student page
        if 'welcome' in current_url or 'student' in current_url or 'logout' in page_text:
            sessions[session_id]['logged_in'] = True
            sessions[session_id]['enrollment'] = username
            
            # Scrape user profile
            user_data = scrape_user_profile(driver, username)
            
            return jsonify({
                'success': True,
                'session_id': session_id,
                'user': user_data
            })
        
        # If still on login page, might be wrong credentials
        if 'login' in current_url:
            return jsonify({
                'success': False,
                'message': 'Login failed. Check your credentials.'
            }), 401
        
        # Otherwise assume success
        sessions[session_id]['logged_in'] = True
        sessions[session_id]['enrollment'] = username
        user_data = scrape_user_profile(driver, username)
        
        return jsonify({
            'success': True,
            'session_id': session_id,
            'user': user_data
        })
            
    except Exception as e:
        print(f"Login error: {e}")
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

def scrape_user_profile(driver, enrollment):
    """Scrape complete user profile from GMS"""
    user_data = {
        'id': str(uuid.uuid4()),
        'enrollment': enrollment,
        'name': '',
        'email': '',
        'phone': '',
        'branch': '',
        'semester': '',
        'section': '',
        'batch': '',
        'father_name': '',
        'mother_name': '',
        'address': '',
        'registered_courses': []
    }
    
    try:
        # First try welcome page
        driver.get(GMS_WELCOME_URL)
        time.sleep(2)
        
        body_text = driver.find_element(By.TAG_NAME, 'body').text
        
        # Extract name from welcome message
        welcome_match = re.search(r'Welcome\s+([A-Z][A-Za-z\s]+)', body_text)
        if welcome_match:
            user_data['name'] = welcome_match.group(1).strip()
        
        # Try to get registered courses
        try:
            tables = driver.find_elements(By.TAG_NAME, 'table')
            for table in tables:
                header_text = table.text
                if 'Course Code' in header_text or 'Subject' in header_text:
                    rows = table.find_elements(By.TAG_NAME, 'tr')
                    for row in rows[1:]:
                        cols = row.find_elements(By.TAG_NAME, 'td')
                        if len(cols) >= 3:
                            user_data['registered_courses'].append({
                                'code': cols[1].text.strip() if len(cols) > 1 else '',
                                'name': cols[2].text.strip() if len(cols) > 2 else '',
                                'type': cols[3].text.strip() if len(cols) > 3 else ''
                            })
                    break
        except:
            pass
        
        # Try profile page for more details
        try:
            driver.get(GMS_PROFILE_URL)
            time.sleep(2)
            
            body_text = driver.find_element(By.TAG_NAME, 'body').text
            
            # Extract email
            email_match = re.search(r'[\w\.-]+@[\w\.-]+\.\w+', body_text)
            if email_match:
                user_data['email'] = email_match.group(0)
            
            # Extract phone
            phone_match = re.search(r'\b[6-9]\d{9}\b', body_text)
            if phone_match:
                user_data['phone'] = phone_match.group(0)
            
            # Try to find table with profile info
            tables = driver.find_elements(By.TAG_NAME, 'table')
            for table in tables:
                rows = table.find_elements(By.TAG_NAME, 'tr')
                for row in rows:
                    cols = row.find_elements(By.TAG_NAME, 'td')
                    if len(cols) >= 2:
                        label = cols[0].text.strip().lower()
                        value = cols[1].text.strip()
                        
                        if 'name' in label and 'father' not in label and 'mother' not in label:
                            if not user_data['name']:
                                user_data['name'] = value
                        elif 'email' in label:
                            user_data['email'] = value
                        elif 'phone' in label or 'mobile' in label:
                            user_data['phone'] = value
                        elif 'branch' in label or 'department' in label:
                            user_data['branch'] = value
                        elif 'semester' in label or 'sem' in label:
                            user_data['semester'] = value
                        elif 'section' in label:
                            user_data['section'] = value
                        elif 'batch' in label or 'year' in label:
                            user_data['batch'] = value
                        elif 'father' in label:
                            user_data['father_name'] = value
                        elif 'mother' in label:
                            user_data['mother_name'] = value
                        elif 'address' in label:
                            user_data['address'] = value
        except:
            pass
        
        # Try registration page for more info
        try:
            driver.get(GMS_REGISTRATION_URL)
            time.sleep(2)
            
            # Enter enrollment and search
            try:
                enroll_field = driver.find_element(By.NAME, 'enrollment')
                enroll_field.clear()
                enroll_field.send_keys(enrollment)
                
                submit = driver.find_element(By.CSS_SELECTOR, 'input[type="submit"]')
                submit.click()
                time.sleep(2)
                
                body_text = driver.find_element(By.TAG_NAME, 'body').text
                
                # Extract info from registration page
                if not user_data['name']:
                    name_match = re.search(r'Name\s*:?\s*([A-Z][A-Za-z\s]+)', body_text)
                    if name_match:
                        user_data['name'] = name_match.group(1).strip()
                
                if not user_data['email']:
                    email_match = re.search(r'[\w\.-]+@[\w\.-]+\.\w+', body_text)
                    if email_match:
                        user_data['email'] = email_match.group(0)
            except:
                pass
        except:
            pass
                
    except Exception as e:
        print(f"Error scraping profile: {e}")
    
    # Default name if not found
    if not user_data['name']:
        user_data['name'] = 'Student'
    
    return user_data

@app.route('/api/profile', methods=['GET'])
def get_profile():
    """Get detailed student profile"""
    session_id = request.headers.get('Authorization', '').replace('Bearer ', '')
    
    if not session_id or session_id not in sessions:
        return jsonify({'success': False, 'message': 'Invalid session'}), 401
    
    driver = sessions[session_id]['driver']
    enrollment = sessions[session_id].get('enrollment', '')
    
    try:
        profile = scrape_user_profile(driver, enrollment)
        return jsonify({
            'success': True,
            'profile': profile
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/attendance', methods=['GET'])
def get_attendance():
    """Scrape attendance data"""
    session_id = request.headers.get('Authorization', '').replace('Bearer ', '')
    
    if not session_id or session_id not in sessions:
        return jsonify({'success': False, 'message': 'Invalid session'}), 401
    
    if not sessions[session_id].get('logged_in'):
        return jsonify({'success': False, 'message': 'Not logged in'}), 401
    
    driver = sessions[session_id]['driver']
    
    try:
        driver.get(GMS_ATTENDANCE_URL)
        time.sleep(3)
        
        attendance_data = []
        
        # Find attendance table
        tables = driver.find_elements(By.TAG_NAME, 'table')
        for table in tables:
            table_text = table.text
            if 'Course Code' in table_text and ('Present' in table_text or 'Attendance' in table_text):
                rows = table.find_elements(By.TAG_NAME, 'tr')
                for row in rows[1:]:
                    cols = row.find_elements(By.TAG_NAME, 'td')
                    if len(cols) >= 7:
                        try:
                            course_code = cols[1].text.strip()
                            course_name = cols[2].text.strip()
                            present_text = cols[-1].text.strip()
                            
                            # Parse "45/50 (90.00%)"
                            match = re.search(r'(\d+)\s*/\s*(\d+)', present_text)
                            percent_match = re.search(r'(\d+\.?\d*)\s*%', present_text)
                            
                            if match:
                                attended = int(match.group(1))
                                total = int(match.group(2))
                                percentage = float(percent_match.group(1)) if percent_match else (attended/total*100 if total > 0 else 0)
                                
                                attendance_data.append({
                                    'subject_code': course_code,
                                    'subject_name': course_name,
                                    'attended_classes': attended,
                                    'total_classes': total,
                                    'percentage': round(percentage, 2)
                                })
                        except:
                            continue
                break
        
        return jsonify({
            'success': True,
            'attendance': attendance_data
        })
                
    except Exception as e:
        print(f"Attendance error: {e}")
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/materials', methods=['GET'])
def get_materials():
    """Get materials categories and subjects"""
    session_id = request.headers.get('Authorization', '').replace('Bearer ', '')
    
    if not session_id or session_id not in sessions:
        return jsonify({'success': False, 'message': 'Invalid session'}), 401
    
    driver = sessions[session_id]['driver']
    
    try:
        driver.get(GMS_MATERIALS_URL)
        time.sleep(3)
        
        categories = []
        subjects = []
        
        # Get categories
        try:
            cat_select = driver.find_element(By.NAME, 'category_name')
            for option in cat_select.find_elements(By.TAG_NAME, 'option'):
                value = option.get_attribute('value')
                if value:
                    categories.append({'value': value, 'name': option.text.strip()})
        except:
            pass
        
        # Get subjects
        try:
            subj_select = driver.find_element(By.NAME, 'course_code')
            for option in subj_select.find_elements(By.TAG_NAME, 'option'):
                value = option.get_attribute('value')
                if value:
                    subjects.append({'value': value, 'name': option.text.strip()})
        except:
            pass
        
        return jsonify({
            'success': True,
            'materials': [],
            'categories': categories,
            'subjects': subjects
        })
                
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/materials/search', methods=['POST'])
def search_materials():
    """Search materials by category and subject"""
    session_id = request.headers.get('Authorization', '').replace('Bearer ', '')
    data = request.json
    category = data.get('category', '')
    subject = data.get('subject', '')
    
    if not session_id or session_id not in sessions:
        return jsonify({'success': False, 'message': 'Invalid session'}), 401
    
    driver = sessions[session_id]['driver']
    
    try:
        driver.get(GMS_MATERIALS_URL)
        time.sleep(2)
        
        # Select category
        if category:
            try:
                Select(driver.find_element(By.NAME, 'category_name')).select_by_value(category)
                time.sleep(1)
            except:
                pass
        
        # Select subject
        if subject:
            try:
                Select(driver.find_element(By.NAME, 'course_code')).select_by_value(subject)
                time.sleep(1)
            except:
                pass
        
        # Submit
        try:
            driver.find_element(By.CSS_SELECTOR, 'input[type="submit"]').click()
            time.sleep(3)
        except:
            pass
        
        materials_data = []
        
        # Find materials table
        tables = driver.find_elements(By.TAG_NAME, 'table')
        for table in tables:
            if 'Download' in table.text or 'File' in table.text:
                rows = table.find_elements(By.TAG_NAME, 'tr')
                for row in rows[1:]:
                    cols = row.find_elements(By.TAG_NAME, 'td')
                    if len(cols) >= 2:
                        download_url = ''
                        try:
                            link = row.find_element(By.TAG_NAME, 'a')
                            download_url = link.get_attribute('href') or ''
                        except:
                            pass
                        
                        materials_data.append({
                            'id': str(uuid.uuid4()),
                            'title': cols[1].text.strip() if len(cols) > 1 else 'Untitled',
                            'subject_code': subject,
                            'subject_name': subject,
                            'type': category or 'document',
                            'uploaded_by': cols[2].text.strip() if len(cols) > 2 else 'Faculty',
                            'uploaded_at': cols[3].text.strip() if len(cols) > 3 else '',
                            'download_url': download_url
                        })
                break
        
        return jsonify({'success': True, 'materials': materials_data})
                
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/quiz', methods=['GET'])
def get_quizzes():
    """Scrape quiz results"""
    session_id = request.headers.get('Authorization', '').replace('Bearer ', '')
    
    if not session_id or session_id not in sessions:
        return jsonify({'success': False, 'message': 'Invalid session'}), 401
    
    driver = sessions[session_id]['driver']
    
    try:
        driver.get(GMS_QUIZ_URL)
        time.sleep(3)
        
        quiz_data = []
        
        # Get quiz options
        try:
            for select in driver.find_elements(By.TAG_NAME, 'select'):
                for option in select.find_elements(By.TAG_NAME, 'option'):
                    value = option.get_attribute('value')
                    if value:
                        quiz_data.append({
                            'id': value,
                            'title': option.text.strip(),
                            'subject_code': '',
                            'subject_name': option.text.strip(),
                            'status': 'completed'
                        })
        except:
            pass
        
        # Check results table
        tables = driver.find_elements(By.TAG_NAME, 'table')
        for table in tables:
            rows = table.find_elements(By.TAG_NAME, 'tr')
            for row in rows[1:]:
                cols = row.find_elements(By.TAG_NAME, 'td')
                if len(cols) >= 3:
                    quiz_data.append({
                        'id': str(uuid.uuid4()),
                        'title': cols[0].text.strip(),
                        'subject_code': cols[1].text.strip() if len(cols) > 1 else '',
                        'subject_name': cols[1].text.strip() if len(cols) > 1 else '',
                        'score': cols[2].text.strip() if len(cols) > 2 else None,
                        'status': 'completed'
                    })
        
        return jsonify({'success': True, 'quizzes': quiz_data})
                
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/midsem', methods=['GET'])
def get_midsem():
    """Scrape mid-semester results"""
    session_id = request.headers.get('Authorization', '').replace('Bearer ', '')
    exam_type = request.args.get('type', '1')
    
    if not session_id or session_id not in sessions:
        return jsonify({'success': False, 'message': 'Invalid session'}), 401
    
    driver = sessions[session_id]['driver']
    
    try:
        url = GMS_MID_SEM_URL if exam_type == '1' else GMS_REMEDIAL_URL
        driver.get(url)
        time.sleep(3)
        
        subjects = []
        results = []
        
        # Get subjects from dropdown
        try:
            for select in driver.find_elements(By.TAG_NAME, 'select'):
                for option in select.find_elements(By.TAG_NAME, 'option'):
                    value = option.get_attribute('value')
                    if value:
                        subjects.append({'code': value, 'name': option.text.strip()})
        except:
            pass
        
        # Check results table
        tables = driver.find_elements(By.TAG_NAME, 'table')
        for table in tables:
            if 'Marks' in table.text:
                rows = table.find_elements(By.TAG_NAME, 'tr')
                for row in rows[1:]:
                    cols = row.find_elements(By.TAG_NAME, 'td')
                    if len(cols) >= 2:
                        results.append({
                            'subject': cols[0].text.strip(),
                            'marks': cols[1].text.strip(),
                            'max_marks': cols[2].text.strip() if len(cols) > 2 else '100'
                        })
                break
        
        return jsonify({
            'success': True,
            'exam_type': f'Mid Sem {exam_type}' if exam_type == '1' else 'Remedial',
            'subjects': subjects,
            'results': results
        })
                
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/library', methods=['GET'])
def get_library():
    """Scrape library books"""
    session_id = request.headers.get('Authorization', '').replace('Bearer ', '')
    
    if not session_id or session_id not in sessions:
        return jsonify({'success': False, 'message': 'Invalid session'}), 401
    
    driver = sessions[session_id]['driver']
    
    try:
        driver.get(GMS_LIBRARY_URL)
        time.sleep(3)
        
        books = []
        
        # Find books table
        tables = driver.find_elements(By.TAG_NAME, 'table')
        for table in tables:
            if 'Book' in table.text or 'Title' in table.text:
                rows = table.find_elements(By.TAG_NAME, 'tr')
                for row in rows[1:]:
                    cols = row.find_elements(By.TAG_NAME, 'td')
                    if len(cols) >= 3:
                        books.append({
                            'id': str(uuid.uuid4()),
                            'title': cols[1].text.strip() if len(cols) > 1 else 'Unknown',
                            'author': cols[2].text.strip() if len(cols) > 2 else '',
                            'issue_date': cols[3].text.strip() if len(cols) > 3 else '',
                            'due_date': cols[4].text.strip() if len(cols) > 4 else '',
                            'status': 'issued'
                        })
                break
        
        return jsonify({'success': True, 'books': books})
                
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/calendar', methods=['GET'])
def get_calendar():
    """Scrape academic calendar"""
    session_id = request.headers.get('Authorization', '').replace('Bearer ', '')
    
    if not session_id or session_id not in sessions:
        return jsonify({'success': False, 'message': 'Invalid session'}), 401
    
    driver = sessions[session_id]['driver']
    
    try:
        driver.get(GMS_CALENDAR_URL)
        time.sleep(3)
        
        events = []
        
        # Find calendar table
        tables = driver.find_elements(By.TAG_NAME, 'table')
        for table in tables:
            rows = table.find_elements(By.TAG_NAME, 'tr')
            for row in rows[1:]:
                cols = row.find_elements(By.TAG_NAME, 'td')
                if len(cols) >= 2:
                    events.append({
                        'id': str(uuid.uuid4()),
                        'title': cols[1].text.strip() if len(cols) > 1 else 'Event',
                        'date': cols[0].text.strip() if cols else '',
                        'description': cols[2].text.strip() if len(cols) > 2 else '',
                        'type': 'academic'
                    })
        
        return jsonify({'success': True, 'events': events})
                
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/holidays', methods=['GET'])
def get_holidays():
    """Get Indian public holidays"""
    year = request.args.get('year', 2025)
    try:
        response = requests.get(
            f'https://date.nager.at/api/v3/publicholidays/{year}/IN',
            timeout=10
        )
        if response.status_code == 200:
            return jsonify({'success': True, 'holidays': response.json()})
    except:
        pass
    
    return jsonify({
        'success': True,
        'holidays': [
            {'date': f'{year}-01-26', 'name': 'Republic Day'},
            {'date': f'{year}-08-15', 'name': 'Independence Day'},
            {'date': f'{year}-10-02', 'name': 'Gandhi Jayanti'},
            {'date': f'{year}-12-25', 'name': 'Christmas'},
        ]
    })

@app.route('/api/logout', methods=['POST'])
def logout():
    """Logout and cleanup"""
    session_id = request.headers.get('Authorization', '').replace('Bearer ', '')
    
    if session_id and session_id in sessions:
        try:
            sessions[session_id]['driver'].quit()
        except:
            pass
        del sessions[session_id]
    
    return jsonify({'success': True})

# Session cleanup thread
def cleanup_sessions():
    while True:
        time.sleep(300)
        current = time.time()
        expired = [s for s, d in sessions.items() if current - d['created'] > 1800]
        for s in expired:
            try:
                sessions[s]['driver'].quit()
            except:
                pass
            del sessions[s]
        if expired:
            print(f"Cleaned {len(expired)} sessions")

if __name__ == '__main__':
    threading.Thread(target=cleanup_sessions, daemon=True).start()
    
    print("=" * 60)
    print("GCET Tracker Backend - Full GMS Scraper")
    print("=" * 60)
    print(f"GMS: {GMS_BASE_URL}")
    print("Server: http://localhost:5000")
    print("=" * 60)
    print("Endpoints:")
    print("  GET  /api/captcha    - Get login captcha")
    print("  POST /api/login      - Login with enrollment/password")
    print("  GET  /api/profile    - Get student profile (name, email)")
    print("  GET  /api/attendance - View attendance")
    print("  GET  /api/materials  - Get material categories")
    print("  POST /api/materials/search - Search materials")
    print("  GET  /api/quiz       - Get quiz results")
    print("  GET  /api/midsem     - Get mid-sem results")
    print("  GET  /api/library    - Get library books")
    print("  GET  /api/calendar   - Get academic calendar")
    print("  GET  /api/holidays   - Get Indian holidays")
    print("  POST /api/logout     - Logout")
    print("=" * 60)
    
    app.run(host='0.0.0.0', port=5000, debug=True)
