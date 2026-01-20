/**
 * GCET Tracker Web Application
 * Main Application Logic
 */

const App = {
  // Current user data
  user: null,

  // Attendance data
  attendance: [],

  // Timetable data
  timetable: {},

  // Currently selected day for timetable
  selectedDay: 0,

  /**
   * Initialize the application
   */
  init() {
    // Check for saved theme
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme) {
      document.documentElement.setAttribute('data-theme', savedTheme);
      const toggle = document.getElementById('dark-mode-toggle');
      if (toggle) toggle.checked = savedTheme === 'dark';
    }

    // Check for saved user session
    const savedUser = localStorage.getItem('gcet_user');
    if (savedUser) {
      this.user = JSON.parse(savedUser);
      this.showDashboard();
    }

    // Load saved data
    this.loadSavedData();

    // Setup event listeners
    this.setupEventListeners();
  },

  /**
   * Setup all event listeners
   */
  setupEventListeners() {
    // Login form
    const loginForm = document.getElementById('login-form');
    if (loginForm) {
      loginForm.addEventListener('submit', (e) => this.handleLogin(e));
    }

    // Toggle password visibility
    const togglePassword = document.getElementById('toggle-password');
    if (togglePassword) {
      togglePassword.addEventListener('click', () => {
        const passwordInput = document.getElementById('password');
        const isPassword = passwordInput.type === 'password';
        passwordInput.type = isPassword ? 'text' : 'password';
        togglePassword.classList.toggle('fa-eye');
        togglePassword.classList.toggle('fa-eye-slash');
      });
    }

    // Logout buttons
    document.getElementById('logout-btn')?.addEventListener('click', () => this.logout());
    document.getElementById('profile-logout-btn')?.addEventListener('click', () => this.logout());

    // Dark mode toggle
    const darkModeToggle = document.getElementById('dark-mode-toggle');
    if (darkModeToggle) {
      darkModeToggle.addEventListener('change', (e) => {
        const theme = e.target.checked ? 'dark' : 'light';
        document.documentElement.setAttribute('data-theme', theme);
        localStorage.setItem('theme', theme);
      });
    }

    // Navigation items
    document.querySelectorAll('.nav-item').forEach(item => {
      item.addEventListener('click', (e) => {
        e.preventDefault();
        const page = item.dataset.page;
        if (page) this.navigateTo(page);
      });
    });

    // Attendance tabs
    document.querySelectorAll('.tab').forEach(tab => {
      tab.addEventListener('click', () => {
        const tabName = tab.dataset.tab;
        this.switchAttendanceTab(tabName);
      });
    });

    // Add class FAB
    document.getElementById('add-class-fab')?.addEventListener('click', () => {
      // Set current day in modal
      const daySelect = document.getElementById('class-day');
      const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
      daySelect.value = days[this.selectedDay];
      this.openModal('add-class-modal');
    });

    // Close modal on overlay click
    document.querySelectorAll('.modal-overlay').forEach(overlay => {
      overlay.addEventListener('click', (e) => {
        if (e.target === overlay) {
          overlay.classList.remove('active');
        }
      });
    });
  },

  /**
   * Load saved data from localStorage
   */
  loadSavedData() {
    // Load attendance
    const savedAttendance = localStorage.getItem('gcet_attendance');
    if (savedAttendance) {
      this.attendance = JSON.parse(savedAttendance);
    }

    // Load timetable
    const savedTimetable = localStorage.getItem('gcet_timetable');
    if (savedTimetable) {
      this.timetable = JSON.parse(savedTimetable);
    }
  },

  /**
   * Handle login form submission
   */
  async handleLogin(e) {
    e.preventDefault();

    const enrollment = document.getElementById('enrollment').value.trim();
    const password = document.getElementById('password').value;
    const loginBtn = document.getElementById('login-btn');
    const loginBtnText = document.getElementById('login-btn-text');
    const loginBtnIcon = document.getElementById('login-btn-icon');
    const loginSpinner = document.getElementById('login-spinner');
    const loginError = document.getElementById('login-error');

    // Hide any previous errors
    loginError.style.display = 'none';

    // Validate inputs
    if (!enrollment || !password) {
      loginError.style.display = 'flex';
      document.getElementById('login-error-text').textContent = 'Please enter your credentials';
      return;
    }

    // Show loading state
    loginBtn.disabled = true;
    loginBtnText.textContent = 'Connecting to GMS...';
    loginBtnIcon.style.display = 'none';
    loginSpinner.style.display = 'block';

    try {
      // Try GMS API login first
      if (window.GmsApi) {
        const result = await GmsApi.login(enrollment, password);

        if (result.success) {
          this.user = result.student;
          localStorage.setItem('gcet_user', JSON.stringify(this.user));

          // Fetch attendance data in background
          this.fetchGmsData();

          this.showDashboard();
          this.showToast('Login successful!', 'success');
          return;
        } else {
          // GMS login failed - check if it's a connection issue
          if (result.error.includes('Unable to connect') || result.error.includes('unavailable')) {
            // CORS or network issue - save credentials and continue with basic session
            console.log('GmsApi: Connection issue, using local session');
            this.user = {
              name: 'Student',
              enrollment: enrollment,
              email: `${enrollment.toLowerCase()}@gcet.ac.in`,
              branch: '',
              semester: '',
              section: '',
              batch: '',
              rollNumber: enrollment
            };
            localStorage.setItem('gcet_user', JSON.stringify(this.user));
            this.showDashboard();
            this.showToast('Logged in (offline mode)', 'warning');
            return;
          }
          throw new Error(result.error);
        }
      } else {
        // GMS API not loaded, use basic session
        this.user = {
          name: 'Student',
          enrollment: enrollment,
          email: `${enrollment.toLowerCase()}@gcet.ac.in`,
          branch: '',
          semester: '',
          section: '',
          batch: '',
          rollNumber: enrollment
        };
        localStorage.setItem('gcet_user', JSON.stringify(this.user));
        this.showDashboard();
        this.showToast('Login successful!', 'success');
      }

    } catch (error) {
      // Show error
      loginError.style.display = 'flex';
      document.getElementById('login-error-text').textContent = error.message || 'Login failed';

    } finally {
      // Reset button state
      loginBtn.disabled = false;
      loginBtnText.textContent = 'Sign In';
      loginBtnIcon.style.display = 'inline';
      loginSpinner.style.display = 'none';
    }
  },

  /**
   * Fetch data from GMS portal (attendance, materials, etc.)
   */
  async fetchGmsData() {
    if (!window.GmsApi) return;

    try {
      // Fetch attendance
      const attendance = await GmsApi.fetchAttendance();
      if (attendance.length > 0) {
        this.attendance = attendance;
        localStorage.setItem('gcet_attendance', JSON.stringify(attendance));
        this.updateDashboardStats();
      }

      // Fetch materials
      const materials = await GmsApi.fetchMaterials();
      if (materials.length > 0) {
        localStorage.setItem('gcet_materials', JSON.stringify(materials));
      }

    } catch (error) {
      console.error('Error fetching GMS data:', error);
    }
  },

  /**
   * Extract a name from enrollment number (placeholder logic)
   */
  extractNameFromEnrollment(enrollment) {
    // In real app, this would come from the server
    return 'Student';
  },

  /**
   * Show the dashboard
   */
  showDashboard() {
    this.hideAllPages();
    document.getElementById('dashboard-page').style.display = 'block';

    // Update greeting
    this.updateGreeting();

    // Update user info
    if (this.user) {
      document.getElementById('dashboard-user-name').textContent = this.user.name;
    }

    // Update stats
    this.updateDashboardStats();

    // Update nav
    this.updateNavigation('dashboard');
  },

  /**
   * Update greeting based on time of day
   */
  updateGreeting() {
    const hour = new Date().getHours();
    let greeting = 'Good Evening';
    if (hour < 12) greeting = 'Good Morning';
    else if (hour < 17) greeting = 'Good Afternoon';

    const greetingEl = document.querySelector('.greeting');
    if (greetingEl) greetingEl.textContent = `${greeting},`;
  },

  /**
   * Update dashboard statistics
   */
  updateDashboardStats() {
    // Calculate overall attendance
    let overall = 0;
    if (this.attendance.length > 0) {
      const total = this.attendance.reduce((sum, a) => sum + a.percentage, 0);
      overall = total / this.attendance.length;
    }

    document.getElementById('stat-attendance').textContent = overall > 0 ? `${overall.toFixed(1)}%` : '--%';
    document.getElementById('stat-subjects').textContent = this.attendance.length || '--';

    // Get next class
    const nextClass = this.getNextClass();
    document.getElementById('stat-next-class').textContent = nextClass || '--';

    // Update status badge
    const statusBadge = document.getElementById('attendance-status');
    if (overall >= 75) {
      statusBadge.className = 'badge badge-success';
      statusBadge.innerHTML = '<i class="fas fa-check-circle"></i> On Track';
    } else if (overall > 0) {
      statusBadge.className = 'badge badge-warning';
      statusBadge.innerHTML = '<i class="fas fa-exclamation-triangle"></i> Needs Attention';
    }
  },

  /**
   * Get the next class from timetable
   */
  getNextClass() {
    const now = new Date();
    const currentDay = now.getDay(); // 0 = Sunday
    const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    const dayName = days[currentDay];

    const todayClasses = this.timetable[dayName] || [];
    const currentTime = now.getHours() * 60 + now.getMinutes();

    // Find next class today
    for (const cls of todayClasses) {
      const [hours, mins] = cls.startTime.split(':').map(Number);
      const classTime = hours * 60 + mins;
      if (classTime > currentTime) {
        return cls.subject.length > 8 ? cls.subject.substring(0, 8) + '..' : cls.subject;
      }
    }

    return null;
  },

  /**
   * Navigate to a page
   */
  navigateTo(page) {
    this.hideAllPages();

    const pageEl = document.getElementById(`${page}-page`);
    if (pageEl) {
      pageEl.style.display = 'block';
      this.updateNavigation(page);

      // Page-specific initialization
      switch (page) {
        case 'attendance':
          this.initAttendancePage();
          break;
        case 'profile':
          this.initProfilePage();
          break;
        case 'timetable':
          this.initTimetablePage();
          break;
        case 'idcard':
          this.initIdCardPage();
          break;
      }
    }
  },

  /**
   * Hide all pages
   */
  hideAllPages() {
    document.querySelectorAll('.page').forEach(page => {
      page.style.display = 'none';
    });
  },

  /**
   * Update navigation active state
   */
  updateNavigation(activePage) {
    document.querySelectorAll('.nav-item').forEach(item => {
      item.classList.toggle('active', item.dataset.page === activePage);
    });
  },

  /**
   * Initialize attendance page
   */
  initAttendancePage() {
    // Calculate overall attendance
    let overall = 0;
    if (this.attendance.length > 0) {
      const total = this.attendance.reduce((sum, a) => sum + a.percentage, 0);
      overall = total / this.attendance.length;
    }

    // Update overall display
    document.getElementById('overall-attendance').textContent = overall > 0 ? `${overall.toFixed(1)}%` : '--%';

    const overallStatus = document.getElementById('overall-status');
    if (overall >= 75) {
      overallStatus.className = 'badge badge-success';
      overallStatus.innerHTML = '<i class="fas fa-check"></i> On Track';
    } else if (overall > 0) {
      overallStatus.className = 'badge badge-warning';
      overallStatus.innerHTML = '<i class="fas fa-exclamation"></i> Need Improvement';
    }

    // Render pie chart
    this.renderPieChart('pie-chart', overall);

    // Render bar chart
    this.renderBarChart('bar-chart', this.attendance);

    // Render subject cards
    this.renderSubjectCards();
  },

  /**
   * Render pie chart
   */
  renderPieChart(containerId, percentage) {
    const container = document.getElementById(containerId);
    if (!container) return;

    const size = 120;
    const strokeWidth = 12;
    const radius = (size - strokeWidth) / 2;
    const circumference = 2 * Math.PI * radius;
    const offset = circumference - (percentage / 100) * circumference;

    container.innerHTML = `
      <svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
        <circle
          cx="${size / 2}"
          cy="${size / 2}"
          r="${radius}"
          fill="none"
          stroke="rgba(255,255,255,0.3)"
          stroke-width="${strokeWidth}"
        />
        <circle
          cx="${size / 2}"
          cy="${size / 2}"
          r="${radius}"
          fill="none"
          stroke="white"
          stroke-width="${strokeWidth}"
          stroke-linecap="round"
          stroke-dasharray="${circumference}"
          stroke-dashoffset="${offset}"
          transform="rotate(-90 ${size / 2} ${size / 2})"
          style="transition: stroke-dashoffset 1s ease"
        />
        <text x="${size / 2}" y="${size / 2 + 5}" text-anchor="middle" fill="white" font-size="20" font-weight="bold">
          ${percentage >= 75 ? '✓' : '!'}
        </text>
      </svg>
    `;
  },

  /**
   * Render bar chart
   */
  renderBarChart(containerId, data) {
    const container = document.getElementById(containerId);
    if (!container || data.length === 0) {
      container.innerHTML = '<div class="empty-state"><div class="empty-text">No attendance data available</div></div>';
      return;
    }

    const maxValue = 100;
    const barWidth = Math.min(40, (container.clientWidth - 40) / data.length - 10);

    let barsHtml = '<div style="display: flex; align-items: flex-end; justify-content: space-around; height: 180px; padding-top: 20px;">';

    data.forEach((item, index) => {
      const height = (item.percentage / maxValue) * 160;
      const color = item.percentage >= 75 ? '#4CAF50' : item.percentage >= 60 ? '#FF9800' : '#E53935';
      const label = item.subjectCode || `S${index + 1}`;

      barsHtml += `
        <div style="display: flex; flex-direction: column; align-items: center;">
          <div style="
            width: ${barWidth}px;
            height: ${height}px;
            background: linear-gradient(to top, ${color}, ${color}dd);
            border-radius: 8px 8px 0 0;
            transition: height 1s ease;
          "></div>
          <div style="font-size: 11px; color: #666; margin-top: 8px; text-align: center; max-width: ${barWidth + 10}px; overflow: hidden; text-overflow: ellipsis;">
            ${label.length > 5 ? label.substring(0, 5) : label}
          </div>
        </div>
      `;
    });

    barsHtml += '</div>';
    container.innerHTML = barsHtml;
  },

  /**
   * Render subject cards
   */
  renderSubjectCards() {
    const container = document.getElementById('subjects-list');
    if (!container) return;

    if (this.attendance.length === 0) {
      container.innerHTML = `
        <div class="empty-state">
          <div class="empty-icon"><i class="fas fa-clipboard-list"></i></div>
          <div class="empty-title">No Subjects</div>
          <div class="empty-text">Attendance data will appear here once synced</div>
        </div>
      `;
      return;
    }

    container.innerHTML = this.attendance.map(subject => {
      const color = subject.percentage >= 75 ? '#4CAF50' : subject.percentage >= 60 ? '#FF9800' : '#E53935';
      const needsClasses = Math.max(0, Math.ceil((0.75 * subject.totalClasses - subject.attendedClasses) / 0.25));
      const canSkip = Math.max(0, Math.floor((subject.attendedClasses - 0.75 * subject.totalClasses) / 0.75));

      return `
        <div class="subject-card">
          <div class="subject-header">
            <div class="progress-circle">
              <svg width="60" height="60" viewBox="0 0 60 60">
                <circle cx="30" cy="30" r="24" fill="none" stroke="${color}33" stroke-width="6"/>
                <circle cx="30" cy="30" r="24" fill="none" stroke="${color}" stroke-width="6"
                  stroke-linecap="round"
                  stroke-dasharray="${2 * Math.PI * 24}"
                  stroke-dashoffset="${2 * Math.PI * 24 * (1 - subject.percentage / 100)}"
                  transform="rotate(-90 30 30)"
                />
              </svg>
              <div class="progress-text" style="color: ${color}">${subject.percentage.toFixed(0)}%</div>
            </div>
            <div class="subject-info">
              <div class="subject-name">${subject.subjectName}</div>
              <div class="subject-code">${subject.subjectCode}</div>
              ${subject.facultyName ? `<div class="faculty-name"><i class="fas fa-user"></i> ${subject.facultyName}</div>` : ''}
            </div>
            <div class="classes-badge" style="background: ${color}15; color: ${color}">
              <div class="count">${subject.attendedClasses}/${subject.totalClasses}</div>
              <div class="label">Classes</div>
            </div>
          </div>
          <div class="progress-bar">
            <div class="fill" style="width: ${subject.percentage}%; background: ${color}"></div>
          </div>
          <div class="subject-footer">
            ${needsClasses > 0
          ? `<span class="status-chip danger"><i class="fas fa-exclamation-triangle"></i> Need ${needsClasses} more classes</span>`
          : `<span class="status-chip success"><i class="fas fa-check-circle"></i> Can skip ${canSkip} classes</span>`
        }
            <span class="target-text">Target: 75%</span>
          </div>
        </div>
      `;
    }).join('');
  },

  /**
   * Switch attendance tab
   */
  switchAttendanceTab(tabName) {
    // Update tab buttons
    document.querySelectorAll('.tab').forEach(tab => {
      tab.classList.toggle('active', tab.dataset.tab === tabName);
    });

    // Show/hide content
    document.getElementById('overview-tab').style.display = tabName === 'overview' ? 'block' : 'none';
    document.getElementById('subjects-tab').style.display = tabName === 'subjects' ? 'block' : 'none';
  },

  /**
   * Initialize profile page
   */
  initProfilePage() {
    if (!this.user) return;

    // Update avatar
    const initials = this.getInitials(this.user.name);
    document.getElementById('profile-avatar').textContent = initials;

    // Update personal info
    document.getElementById('profile-name').textContent = this.user.name || 'Student';
    document.getElementById('profile-email').textContent = this.user.email || '';
    document.getElementById('profile-enrollment').textContent = this.user.enrollment || 'N/A';

    // Update academic info
    document.getElementById('profile-branch').textContent = this.user.branch || '--';
    document.getElementById('profile-semester').textContent = this.user.semester || '--';
    document.getElementById('profile-section').textContent = this.user.section || '--';
    document.getElementById('profile-batch').textContent = this.user.batch || '--';

    // Update stats
    let overall = 0;
    if (this.attendance.length > 0) {
      const total = this.attendance.reduce((sum, a) => sum + a.percentage, 0);
      overall = total / this.attendance.length;
    }

    document.getElementById('profile-stat-attendance').textContent = overall > 0 ? `${overall.toFixed(0)}%` : '--%';
    document.getElementById('profile-stat-subjects').textContent = this.attendance.length || '--';
    document.getElementById('profile-stat-materials').textContent = '--';
  },

  /**
   * Initialize ID card page
   */
  initIdCardPage() {
    if (!this.user) return;

    const initials = this.getInitials(this.user.name);
    document.getElementById('idcard-avatar').textContent = initials;
    document.getElementById('idcard-name').textContent = (this.user.name || 'STUDENT').toUpperCase();
    document.getElementById('idcard-enrollment').textContent = this.user.enrollment || 'XXXXXXXXXX';
    document.getElementById('idcard-branch').textContent = this.user.branch || 'Engineering';
    document.getElementById('idcard-semester').textContent = this.user.semester?.replace(' Semester', '') || '--';
    document.getElementById('idcard-section').textContent = this.user.section || '--';
    document.getElementById('idcard-batch').textContent = this.user.batch || '--';
  },

  /**
   * Initialize timetable page
   */
  initTimetablePage() {
    // Set selected day to current weekday
    const today = new Date().getDay();
    this.selectedDay = today === 0 ? 0 : today - 1; // Sunday defaults to Monday

    this.renderDaySelector();
    this.renderTimetable();
  },

  /**
   * Render day selector
   */
  renderDaySelector() {
    const container = document.getElementById('day-selector');
    if (!container) return;

    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const today = new Date();
    const currentDay = today.getDay(); // 0 = Sunday

    // Get dates for this week (starting Monday)
    const monday = new Date(today);
    monday.setDate(today.getDate() - (currentDay === 0 ? 6 : currentDay - 1));

    container.innerHTML = days.map((day, index) => {
      const date = new Date(monday);
      date.setDate(monday.getDate() + index);
      const isToday = date.toDateString() === today.toDateString();
      const isSelected = index === this.selectedDay;

      return `
        <button class="day-btn ${isSelected ? 'active' : ''} ${isToday ? 'today' : ''}" 
                onclick="App.selectDay(${index})">
          <span class="day-name">${day}</span>
          <span class="day-date">${date.getDate()}</span>
        </button>
      `;
    }).join('');
  },

  /**
   * Select a day in timetable
   */
  selectDay(index) {
    this.selectedDay = index;
    this.renderDaySelector();
    this.renderTimetable();
  },

  /**
   * Render timetable for selected day
   */
  renderTimetable() {
    const container = document.getElementById('timetable-content');
    if (!container) return;

    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    const dayName = days[this.selectedDay];
    const classes = this.timetable[dayName] || [];

    // Sort by start time
    classes.sort((a, b) => a.startTime.localeCompare(b.startTime));

    if (classes.length === 0) {
      container.innerHTML = `
        <div class="empty-state">
          <div class="empty-icon"><i class="fas fa-calendar-day"></i></div>
          <div class="empty-title">No Classes Today</div>
          <div class="empty-text">Tap the + button to add your first class for ${dayName.charAt(0).toUpperCase() + dayName.slice(1)}</div>
          <button class="btn btn-outline mt-lg" onclick="document.getElementById('add-class-fab').click()">
            <i class="fas fa-plus"></i> Add Class
          </button>
        </div>
      `;
      return;
    }

    container.innerHTML = classes.map((cls, index) => `
      <div class="class-card ${cls.isLab ? 'lab' : 'lecture'}" data-index="${index}">
        <div class="accent-bar"></div>
        <div class="time-section">
          <span class="time">${this.formatTime(cls.startTime)}</span>
          <i class="fas fa-arrow-down arrow"></i>
          <span class="time">${this.formatTime(cls.endTime)}</span>
        </div>
        <div class="details-section">
          <span class="type-badge">${cls.isLab ? 'Lab' : 'Lecture'}</span>
          <div class="subject-name">${cls.subject || 'No Subject'}</div>
          <div class="meta-info">
            ${cls.faculty ? `<span class="meta-item"><i class="fas fa-user"></i> ${cls.faculty}</span>` : ''}
            ${cls.room ? `<span class="meta-item"><i class="fas fa-map-marker-alt"></i> ${cls.room}</span>` : ''}
          </div>
        </div>
        <button class="back-btn" onclick="App.deleteClass('${dayName}', ${index})" title="Delete" style="color: #999;">
          <i class="fas fa-trash"></i>
        </button>
      </div>
    `).join('');
  },

  /**
   * Format time from 24h to 12h format
   */
  formatTime(time) {
    if (!time) return '--';
    const [hours, mins] = time.split(':').map(Number);
    const period = hours >= 12 ? 'PM' : 'AM';
    const h = hours % 12 || 12;
    return `${h}:${mins.toString().padStart(2, '0')} ${period}`;
  },

  /**
   * Add a new class to timetable
   */
  addNewClass() {
    const subject = document.getElementById('class-subject').value.trim();
    const code = document.getElementById('class-code').value.trim();
    const faculty = document.getElementById('class-faculty').value.trim();
    const room = document.getElementById('class-room').value.trim();
    const day = document.getElementById('class-day').value;
    const startTime = document.getElementById('class-start').value;
    const endTime = document.getElementById('class-end').value;
    const isLab = document.getElementById('class-is-lab').checked;

    if (!subject || !startTime || !endTime) {
      this.showToast('Please fill all required fields', 'error');
      return;
    }

    // Initialize day array if needed
    if (!this.timetable[day]) {
      this.timetable[day] = [];
    }

    // Add class
    this.timetable[day].push({
      subject,
      code,
      faculty,
      room,
      startTime,
      endTime,
      isLab
    });

    // Save to localStorage
    localStorage.setItem('gcet_timetable', JSON.stringify(this.timetable));

    // Close modal and refresh
    this.closeModal('add-class-modal');
    this.renderTimetable();
    this.showToast('Class added successfully!', 'success');

    // Reset form
    document.getElementById('add-class-form').reset();
  },

  /**
   * Delete a class from timetable
   */
  deleteClass(day, index) {
    if (!confirm('Delete this class?')) return;

    if (this.timetable[day]) {
      this.timetable[day].splice(index, 1);
      localStorage.setItem('gcet_timetable', JSON.stringify(this.timetable));
      this.renderTimetable();
      this.showToast('Class deleted', 'success');
    }
  },

  /**
   * Get initials from name
   */
  getInitials(name) {
    if (!name) return 'ST';
    const parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name[0].toUpperCase();
  },

  /**
   * Logout user
   */
  logout() {
    if (!confirm('Are you sure you want to sign out?')) return;

    this.user = null;
    localStorage.removeItem('gcet_user');

    this.hideAllPages();
    document.getElementById('login-page').style.display = 'flex';

    // Clear form
    document.getElementById('login-form').reset();
    document.getElementById('login-error').style.display = 'none';

    this.showToast('Logged out successfully', 'success');
  },

  /**
   * Open modal
   */
  openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
      modal.classList.add('active');
    }
  },

  /**
   * Close modal
   */
  closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
      modal.classList.remove('active');
    }
  },

  /**
   * Show toast notification
   */
  showToast(message, type = 'info') {
    const container = document.getElementById('toast-container');
    if (!container) return;

    const toast = document.createElement('div');
    toast.className = 'toast';

    let icon = 'info-circle';
    let color = '#2196F3';
    if (type === 'success') { icon = 'check-circle'; color = '#4CAF50'; }
    if (type === 'error') { icon = 'exclamation-circle'; color = '#E53935'; }
    if (type === 'warning') { icon = 'exclamation-triangle'; color = '#FF9800'; }

    toast.innerHTML = `
      <i class="fas fa-${icon}" style="color: ${color}"></i>
      <span>${message}</span>
    `;

    container.appendChild(toast);

    // Remove after 3 seconds
    setTimeout(() => {
      toast.style.opacity = '0';
      toast.style.transform = 'translateX(100%)';
      setTimeout(() => toast.remove(), 300);
    }, 3000);
  },

  /**
   * Delay utility
   */
  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  },

  /**
   * Show timetable settings (placeholder)
   */
  showTimetableSettings() {
    this.showToast('Settings coming soon!', 'info');
  }
};

// Initialize app when DOM is ready
document.addEventListener('DOMContentLoaded', () => App.init());
