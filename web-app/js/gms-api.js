/**
 * GCET Tracker - GMS Portal API Service
 * Handles communication with the GMS portal for authentication and data fetching
 */

const GmsApi = {
    // GMS Portal URLs
    BASE_URL: 'http://202.129.240.148:8080/GIS',

    get LOGIN_URL() { return `${this.BASE_URL}/LoginCheckStudent.do`; },
    get WELCOME_URL() { return `${this.BASE_URL}/Student/WelCome.jsp`; },
    get ATTENDANCE_URL() { return `${this.BASE_URL}/Student/ViewMyAttendance.jsp`; },
    get MATERIALS_URL() { return `${this.BASE_URL}/Student/ViewUploadMaterialNew.jsp`; },
    get PROFILE_URL() { return `${this.BASE_URL}/Student/Profile/ViewProfile.jsp`; },
    get MID_SEM_URL() { return `${this.BASE_URL}/Stu_ViewMidSemMarks.jsp`; },

    /**
     * MD5 Hash function (same as Flutter app uses)
     */
    md5(string) {
        function md5cycle(x, k) {
            var a = x[0], b = x[1], c = x[2], d = x[3];
            a = ff(a, b, c, d, k[0], 7, -680876936);
            d = ff(d, a, b, c, k[1], 12, -389564586);
            c = ff(c, d, a, b, k[2], 17, 606105819);
            b = ff(b, c, d, a, k[3], 22, -1044525330);
            a = ff(a, b, c, d, k[4], 7, -176418897);
            d = ff(d, a, b, c, k[5], 12, 1200080426);
            c = ff(c, d, a, b, k[6], 17, -1473231341);
            b = ff(b, c, d, a, k[7], 22, -45705983);
            a = ff(a, b, c, d, k[8], 7, 1770035416);
            d = ff(d, a, b, c, k[9], 12, -1958414417);
            c = ff(c, d, a, b, k[10], 17, -42063);
            b = ff(b, c, d, a, k[11], 22, -1990404162);
            a = ff(a, b, c, d, k[12], 7, 1804603682);
            d = ff(d, a, b, c, k[13], 12, -40341101);
            c = ff(c, d, a, b, k[14], 17, -1502002290);
            b = ff(b, c, d, a, k[15], 22, 1236535329);
            a = gg(a, b, c, d, k[1], 5, -165796510);
            d = gg(d, a, b, c, k[6], 9, -1069501632);
            c = gg(c, d, a, b, k[11], 14, 643717713);
            b = gg(b, c, d, a, k[0], 20, -373897302);
            a = gg(a, b, c, d, k[5], 5, -701558691);
            d = gg(d, a, b, c, k[10], 9, 38016083);
            c = gg(c, d, a, b, k[15], 14, -660478335);
            b = gg(b, c, d, a, k[4], 20, -405537848);
            a = gg(a, b, c, d, k[9], 5, 568446438);
            d = gg(d, a, b, c, k[14], 9, -1019803690);
            c = gg(c, d, a, b, k[3], 14, -187363961);
            b = gg(b, c, d, a, k[8], 20, 1163531501);
            a = gg(a, b, c, d, k[13], 5, -1444681467);
            d = gg(d, a, b, c, k[2], 9, -51403784);
            c = gg(c, d, a, b, k[7], 14, 1735328473);
            b = gg(b, c, d, a, k[12], 20, -1926607734);
            a = hh(a, b, c, d, k[5], 4, -378558);
            d = hh(d, a, b, c, k[8], 11, -2022574463);
            c = hh(c, d, a, b, k[11], 16, 1839030562);
            b = hh(b, c, d, a, k[14], 23, -35309556);
            a = hh(a, b, c, d, k[1], 4, -1530992060);
            d = hh(d, a, b, c, k[4], 11, 1272893353);
            c = hh(c, d, a, b, k[7], 16, -155497632);
            b = hh(b, c, d, a, k[10], 23, -1094730640);
            a = hh(a, b, c, d, k[13], 4, 681279174);
            d = hh(d, a, b, c, k[0], 11, -358537222);
            c = hh(c, d, a, b, k[3], 16, -722521979);
            b = hh(b, c, d, a, k[6], 23, 76029189);
            a = hh(a, b, c, d, k[9], 4, -640364487);
            d = hh(d, a, b, c, k[12], 11, -421815835);
            c = hh(c, d, a, b, k[15], 16, 530742520);
            b = hh(b, c, d, a, k[2], 23, -995338651);
            a = ii(a, b, c, d, k[0], 6, -198630844);
            d = ii(d, a, b, c, k[7], 10, 1126891415);
            c = ii(c, d, a, b, k[14], 15, -1416354905);
            b = ii(b, c, d, a, k[5], 21, -57434055);
            a = ii(a, b, c, d, k[12], 6, 1700485571);
            d = ii(d, a, b, c, k[3], 10, -1894986606);
            c = ii(c, d, a, b, k[10], 15, -1051523);
            b = ii(b, c, d, a, k[1], 21, -2054922799);
            a = ii(a, b, c, d, k[8], 6, 1873313359);
            d = ii(d, a, b, c, k[15], 10, -30611744);
            c = ii(c, d, a, b, k[6], 15, -1560198380);
            b = ii(b, c, d, a, k[13], 21, 1309151649);
            a = ii(a, b, c, d, k[4], 6, -145523070);
            d = ii(d, a, b, c, k[11], 10, -1120210379);
            c = ii(c, d, a, b, k[2], 15, 718787259);
            b = ii(b, c, d, a, k[9], 21, -343485551);
            x[0] = add32(a, x[0]);
            x[1] = add32(b, x[1]);
            x[2] = add32(c, x[2]);
            x[3] = add32(d, x[3]);
        }

        function cmn(q, a, b, x, s, t) {
            a = add32(add32(a, q), add32(x, t));
            return add32((a << s) | (a >>> (32 - s)), b);
        }

        function ff(a, b, c, d, x, s, t) {
            return cmn((b & c) | ((~b) & d), a, b, x, s, t);
        }

        function gg(a, b, c, d, x, s, t) {
            return cmn((b & d) | (c & (~d)), a, b, x, s, t);
        }

        function hh(a, b, c, d, x, s, t) {
            return cmn(b ^ c ^ d, a, b, x, s, t);
        }

        function ii(a, b, c, d, x, s, t) {
            return cmn(c ^ (b | (~d)), a, b, x, s, t);
        }

        function md51(s) {
            var n = s.length,
                state = [1732584193, -271733879, -1732584194, 271733878], i;
            for (i = 64; i <= s.length; i += 64) {
                md5cycle(state, md5blk(s.substring(i - 64, i)));
            }
            s = s.substring(i - 64);
            var tail = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            for (i = 0; i < s.length; i++)
                tail[i >> 2] |= s.charCodeAt(i) << ((i % 4) << 3);
            tail[i >> 2] |= 0x80 << ((i % 4) << 3);
            if (i > 55) {
                md5cycle(state, tail);
                for (i = 0; i < 16; i++) tail[i] = 0;
            }
            tail[14] = n * 8;
            md5cycle(state, tail);
            return state;
        }

        function md5blk(s) {
            var md5blks = [], i;
            for (i = 0; i < 64; i += 4) {
                md5blks[i >> 2] = s.charCodeAt(i) +
                    (s.charCodeAt(i + 1) << 8) +
                    (s.charCodeAt(i + 2) << 16) +
                    (s.charCodeAt(i + 3) << 24);
            }
            return md5blks;
        }

        var hex_chr = '0123456789abcdef'.split('');

        function rhex(n) {
            var s = '', j = 0;
            for (; j < 4; j++)
                s += hex_chr[(n >> (j * 8 + 4)) & 0x0F] + hex_chr[(n >> (j * 8)) & 0x0F];
            return s;
        }

        function hex(x) {
            for (var i = 0; i < x.length; i++)
                x[i] = rhex(x[i]);
            return x.join('');
        }

        function add32(a, b) {
            return (a + b) & 0xFFFFFFFF;
        }

        return hex(md51(string));
    },

    /**
     * Login to GMS Portal
     * @param {string} enrollment - Enrollment number
     * @param {string} password - Password (plain text, will be MD5 hashed)
     * @returns {Promise<{success: boolean, student?: object, error?: string}>}
     */
    async login(enrollment, password) {
        try {
            console.log('GmsApi: Starting login for', enrollment);

            // Hash password with MD5 (same as Flutter app)
            const passwordMd5 = this.md5(password);
            console.log('GmsApi: Password hashed');

            // Create form data
            const formData = new URLSearchParams();
            formData.append('login_id', enrollment);
            formData.append('pass', passwordMd5);
            formData.append('login_type', 'Normal');

            // Login request
            const response = await fetch(this.LOGIN_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: formData.toString(),
                credentials: 'include',
            });

            console.log('GmsApi: Login response status:', response.status);

            const html = await response.text();
            const lowerHtml = html.toLowerCase();

            // Check for login failure indicators
            if (lowerHtml.includes('invalid') ||
                lowerHtml.includes('wrong password') ||
                lowerHtml.includes('incorrect')) {
                return { success: false, error: 'Invalid enrollment number or password' };
            }

            // Try to fetch welcome page to verify login and get profile data
            const welcomeResponse = await fetch(this.WELCOME_URL, {
                credentials: 'include',
            });

            const welcomeHtml = await welcomeResponse.text();
            const welcomeLower = welcomeHtml.toLowerCase();

            // Check if still on login page
            if (welcomeLower.includes('login_id') ||
                welcomeLower.includes('name="pass"') ||
                welcomeLower.includes('studentlogin.jsp')) {
                return { success: false, error: 'Login failed. Please check your credentials.' };
            }

            // Check for success indicators
            const isLoggedIn = welcomeLower.includes('logout') ||
                welcomeLower.includes('welcome') ||
                welcomeLower.includes('student');

            if (isLoggedIn) {
                // Parse profile from welcome page
                const student = this.parseProfile(welcomeHtml, enrollment);
                return { success: true, student };
            }

            return { success: false, error: 'Login failed. Please try again.' };

        } catch (error) {
            console.error('GmsApi: Login error:', error);

            // CORS error handling - GMS portal doesn't allow cross-origin requests
            if (error.message.includes('Failed to fetch') || error.name === 'TypeError') {
                return {
                    success: false,
                    error: 'Unable to connect to GMS Portal. The portal may be temporarily unavailable or requires direct network access.'
                };
            }

            return { success: false, error: 'GMS Portal is currently unavailable.' };
        }
    },

    /**
     * Parse profile from welcome page HTML
     */
    parseProfile(html, enrollment) {
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, 'text/html');

        let name = '';
        let email = '';
        let branch = '';
        let semester = '';
        let section = '';
        let batch = '';

        // Parse tables for profile data
        const tables = doc.querySelectorAll('table');
        tables.forEach(table => {
            const rows = table.querySelectorAll('tr');
            rows.forEach(row => {
                const cols = row.querySelectorAll('td');
                if (cols.length >= 2) {
                    const label = cols[0].textContent.trim().toLowerCase();
                    const value = cols[1].textContent.trim();

                    if (label.includes('name') && !label.includes('father') && !label.includes('mother') && !label.includes('course')) {
                        if (!name && value.length > 2) name = value;
                    } else if (label.includes('email')) {
                        if (!email && value.includes('@')) email = value;
                    } else if (label.includes('branch') || label.includes('department')) {
                        if (!branch) branch = value;
                    } else if (label.includes('semester') || label.includes('sem')) {
                        if (!semester) semester = value;
                    } else if (label.includes('section') || label.includes('class')) {
                        if (!section) section = value;
                    } else if (label.includes('batch') || label.includes('admission year')) {
                        if (!batch) batch = value;
                    }
                }
            });
        });

        // Fallback email extraction
        if (!email) {
            const emailMatch = html.match(/[\w.-]+@[\w.-]+\.\w+/);
            if (emailMatch) email = emailMatch[0];
        }

        return {
            name: name || 'Student',
            enrollment: enrollment,
            email: email || `${enrollment.toLowerCase()}@gcet.ac.in`,
            branch: branch || '',
            semester: semester || '',
            section: section || '',
            batch: batch || '',
            rollNumber: enrollment
        };
    },

    /**
     * Fetch attendance data from GMS Portal
     */
    async fetchAttendance() {
        try {
            const response = await fetch(this.ATTENDANCE_URL, {
                credentials: 'include',
            });

            const html = await response.text();
            return this.parseAttendance(html);

        } catch (error) {
            console.error('GmsApi: Attendance fetch error:', error);
            return [];
        }
    },

    /**
     * Parse attendance from HTML
     */
    parseAttendance(html) {
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, 'text/html');
        const attendance = [];

        const tables = doc.querySelectorAll('table');
        tables.forEach(table => {
            const tableText = table.textContent;

            if (tableText.includes('Course Code') &&
                (tableText.includes('Present') || tableText.includes('Attendance'))) {

                const rows = table.querySelectorAll('tr');
                for (let i = 1; i < rows.length; i++) {
                    const cols = rows[i].querySelectorAll('td');
                    if (cols.length >= 4) {
                        try {
                            const courseCode = cols[1]?.textContent.trim() || '';
                            const courseName = cols[2]?.textContent.trim() || '';
                            const presentText = cols[cols.length - 1]?.textContent.trim() || '';

                            // Parse "27/30" format
                            const match = presentText.match(/(\d+)\s*\/\s*(\d+)/);
                            // Parse "90%" format
                            const percentMatch = presentText.match(/(\d+\.?\d*)\s*%/);

                            if (match) {
                                const attended = parseInt(match[1]);
                                const total = parseInt(match[2]);
                                const percentage = percentMatch
                                    ? parseFloat(percentMatch[1])
                                    : (total > 0 ? (attended / total * 100) : 0);

                                attendance.push({
                                    subjectCode: courseCode,
                                    subjectName: courseName,
                                    attendedClasses: attended,
                                    totalClasses: total,
                                    percentage: percentage,
                                    facultyName: cols.length > 3 ? cols[3]?.textContent.trim() : ''
                                });
                            }
                        } catch (e) {
                            console.warn('GmsApi: Error parsing attendance row:', e);
                        }
                    }
                }
            }
        });

        return attendance;
    },

    /**
     * Fetch materials from GMS Portal
     */
    async fetchMaterials() {
        try {
            const response = await fetch(this.MATERIALS_URL, {
                credentials: 'include',
            });

            const html = await response.text();
            return this.parseMaterials(html);

        } catch (error) {
            console.error('GmsApi: Materials fetch error:', error);
            return [];
        }
    },

    /**
     * Parse materials from HTML
     */
    parseMaterials(html) {
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, 'text/html');
        const materials = [];

        const tables = doc.querySelectorAll('table');
        tables.forEach(table => {
            const tableText = table.textContent.toLowerCase();

            if (tableText.includes('download') || tableText.includes('file')) {
                const rows = table.querySelectorAll('tr');

                for (let i = 1; i < rows.length; i++) {
                    const cols = rows[i].querySelectorAll('td');
                    const link = rows[i].querySelector('a');

                    if (cols.length >= 2 && link) {
                        let url = link.getAttribute('href');
                        if (url && !url.startsWith('http')) {
                            url = `${this.BASE_URL}/${url}`;
                        }

                        materials.push({
                            id: `${Date.now()}_${i}`,
                            title: cols[1]?.textContent.trim() || `Material ${i}`,
                            subjectCode: cols[0]?.textContent.trim() || '',
                            faculty: cols.length > 2 ? cols[2]?.textContent.trim() : '',
                            date: cols.length > 3 ? cols[3]?.textContent.trim() : '',
                            url: url
                        });
                    }
                }
            }
        });

        return materials;
    },

    /**
     * Fetch Mid Semester Results
     */
    async fetchMidSemResults() {
        try {
            const response = await fetch(this.MID_SEM_URL, {
                credentials: 'include',
            });

            const html = await response.text();
            return this.parseMidSemResults(html);

        } catch (error) {
            console.error('GmsApi: Mid Sem results fetch error:', error);
            return [];
        }
    },

    /**
     * Parse Mid Sem results from HTML
     */
    parseMidSemResults(html) {
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, 'text/html');
        const results = [];

        const tables = doc.querySelectorAll('table');
        tables.forEach(table => {
            const tableText = table.textContent;

            if (tableText.includes('Course') && tableText.includes('Marks')) {
                const rows = table.querySelectorAll('tr');

                for (let i = 1; i < rows.length; i++) {
                    const cols = rows[i].querySelectorAll('td');
                    if (cols.length >= 3) {
                        results.push({
                            subjectCode: cols[0]?.textContent.trim() || '',
                            subjectName: cols[1]?.textContent.trim() || '',
                            marks: cols[2]?.textContent.trim() || '',
                            totalMarks: cols.length > 3 ? cols[3]?.textContent.trim() : '30'
                        });
                    }
                }
            }
        });

        return results;
    }
};

// Export for use in app.js
window.GmsApi = GmsApi;
