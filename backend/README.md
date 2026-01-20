# GCET Tracker Backend

Python Flask backend for the GCET Tracker Flutter app. Uses Selenium for web scraping the GMS portal.

## Setup

1. Install Python 3.10+ 
2. Install Chrome browser
3. Install dependencies:

```bash
cd backend
pip install -r requirements.txt
```

4. Run the server:

```bash
python app.py
```

The server will start on `http://localhost:5000`

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/captcha` | GET | Get captcha image from GMS |
| `/api/login` | POST | Login with credentials |
| `/api/attendance` | GET | Get attendance data |
| `/api/materials` | GET | Get study materials |
| `/api/quiz` | GET | Get quizzes |
| `/api/library` | GET | Get library books |
| `/api/calendar` | GET | Get calendar events |

## Notes

- Selenium runs in headless Chrome mode
- Sessions expire after 30 minutes of inactivity
- Mock data is returned if scraping fails
