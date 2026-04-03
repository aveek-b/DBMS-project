"""
Database Connection and Operations Module
Handles Oracle database connectivity and operations
"""

import oracledb
from flask import current_app, g
from flask_login import UserMixin
from werkzeug.security import generate_password_hash, check_password_hash


class User(UserMixin):
    """User model for Flask-Login."""

    def __init__(self, user_id, username, email, role, first_name,
                 last_name, phone_number=None, is_active=True):
        self.id = user_id
        self.user_id = user_id
        self.username = username
        self.email = email
        self.role = role
        self.first_name = first_name
        self.last_name = last_name
        self.phone_number = phone_number
        self._is_active = is_active

    @property
    def is_active(self):
        return self._is_active

    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name or ''}".strip()

    def is_admin(self):
        return self.role == 'ADMIN'

    def is_warden(self):
        return self.role == 'WARDEN'

    def is_student(self):
        return self.role == 'STUDENT'


# ============================================
# Database Connection
# ============================================

def get_db_connection():
    """Get database connection from Flask g object or create new one."""
    if 'db_conn' not in g:
        try:
            g.db_conn = oracledb.connect(
                user=current_app.config['ORACLE_USER'],
                password=current_app.config['ORACLE_PASSWORD'],
                dsn=current_app.config['ORACLE_DSN']
            )
        except oracledb.Error as e:
            current_app.logger.error(f"Database connection error: {e}")
            raise
    return g.db_conn


def close_db_connection(e=None):
    """Close database connection."""
    db_conn = g.pop('db_conn', None)
    if db_conn is not None:
        db_conn.close()


def execute_query(query, params=None, fetch='all'):
    """Execute a SELECT query and return results."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(query, params or {})
        if fetch == 'one':
            result = cursor.fetchone()
        elif fetch == 'all':
            result = cursor.fetchall()
        else:
            result = None

        columns = [desc[0].lower() for desc in cursor.description] if cursor.description else []

        if fetch == 'one' and result:
            return dict(zip(columns, result))
        elif fetch == 'all' and result:
            return [dict(zip(columns, row)) for row in result]
        return result
    finally:
        cursor.close()


def execute_procedure(proc_name, params):
    """Execute a stored procedure with parameters."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        out_vars = {}
        call_params = []
        for param in params:
            if param.get('direction') == 'OUT':
                if param.get('type') == 'NUMBER':
                    out_vars[param['name']] = cursor.var(oracledb.NUMBER)
                elif param.get('type') == 'CLOB':
                    out_vars[param['name']] = cursor.var(oracledb.CLOB)
                else:
                    out_vars[param['name']] = cursor.var(oracledb.STRING, 4000)
                call_params.append(out_vars[param['name']])
            else:
                call_params.append(param.get('value'))

        cursor.callproc(proc_name, call_params)
        conn.commit()
        return {name: var.getvalue() for name, var in out_vars.items()}
    except oracledb.Error:
        conn.rollback()
        raise
    finally:
        cursor.close()


def execute_function(func_name, params, return_type='NUMBER'):
    """Execute a stored function and return result."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        if return_type == 'NUMBER':
            result = cursor.callfunc(func_name, oracledb.NUMBER, params)
        elif return_type == 'CURSOR':
            result = cursor.callfunc(func_name, oracledb.CURSOR, params)
        else:
            result = cursor.callfunc(func_name, oracledb.STRING, params)
        return result
    finally:
        cursor.close()


def execute_dml(query, params=None):
    """Execute INSERT, UPDATE, or DELETE query."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(query, params or {})
        conn.commit()
        return cursor.rowcount
    except oracledb.Error:
        conn.rollback()
        raise
    finally:
        cursor.close()


# ============================================
# User Authentication Functions
# ============================================

def get_user_by_id(user_id):
    """Get user by ID for Flask-Login."""
    query = """
        SELECT user_id, username, email, role, first_name, last_name,
               phone_number, is_active
        FROM users
        WHERE user_id = :user_id
    """
    result = execute_query(query, {'user_id': user_id}, fetch='one')
    if result:
        return User(
            user_id=result['user_id'],
            username=result['username'],
            email=result['email'],
            role=result['role'],
            first_name=result['first_name'],
            last_name=result['last_name'],
            phone_number=result['phone_number'],
            is_active=result['is_active'] == 'Y'
        )
    return None


def get_user_by_username(username):
    """Get user by username."""
    query = """
        SELECT user_id, username, email, password_hash, role, first_name,
               last_name, phone_number, is_active
        FROM users
        WHERE LOWER(username) = LOWER(:username)
    """
    return execute_query(query, {'username': username}, fetch='one')


def get_user_by_email(email):
    """Get user by email."""
    query = """
        SELECT user_id, username, email, password_hash, role, first_name,
               last_name, phone_number, is_active
        FROM users
        WHERE LOWER(email) = LOWER(:email)
    """
    return execute_query(query, {'email': email}, fetch='one')


def verify_user(username_or_email, password):
    """Verify user credentials."""
    user = get_user_by_username(username_or_email)
    if not user:
        user = get_user_by_email(username_or_email)
    if user and check_password_hash(user['password_hash'], password):
        if user['is_active'] == 'Y':
            return User(
                user_id=user['user_id'],
                username=user['username'],
                email=user['email'],
                role=user['role'],
                first_name=user['first_name'],
                last_name=user['last_name'],
                phone_number=user['phone_number'],
                is_active=True
            )
    return None


def create_user(username, email, password, role, first_name,
                last_name=None, phone_number=None):
    """Create a new user."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        user_id = cursor.var(oracledb.NUMBER)
        cursor.execute("""
            INSERT INTO users (user_id, username, email, password_hash, role,
                               first_name, last_name, phone_number, is_active, created_at)
            VALUES (seq_users.NEXTVAL, :username, :email, :password_hash, :role,
                    :first_name, :last_name, :phone_number, 'Y', CURRENT_TIMESTAMP)
            RETURNING user_id INTO :user_id
        """, {
            'username': username,
            'email': email,
            'password_hash': generate_password_hash(password),
            'role': role,
            'first_name': first_name,
            'last_name': last_name,
            'phone_number': phone_number,
            'user_id': user_id
        })
        conn.commit()
        return int(user_id.getvalue()[0])
    except oracledb.Error:
        conn.rollback()
        raise
    finally:
        cursor.close()


def update_last_login(user_id):
    """Update user's last login timestamp."""
    execute_dml(
        "UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE user_id = :user_id",
        {'user_id': user_id}
    )


# ============================================
# Student Functions
# ============================================

def get_student_by_user_id(user_id):
    """Get student profile by user ID."""
    query = """
        SELECT s.*, u.email, u.phone_number, u.first_name, u.last_name,
               r.room_number, r.room_type, r.floor_number,
               hb.block_name, hb.block_type
        FROM students s
        JOIN users u ON s.user_id = u.user_id
        LEFT JOIN rooms r ON s.room_id = r.room_id
        LEFT JOIN hostel_blocks hb ON r.block_id = hb.block_id
        WHERE s.user_id = :user_id
    """
    return execute_query(query, {'user_id': user_id}, fetch='one')


def get_student_dashboard_data(student_id):
    """Get student dashboard summary data."""
    query = "SELECT * FROM vw_student_dashboard WHERE student_id = :student_id"
    return execute_query(query, {'student_id': student_id}, fetch='one')


def create_student_profile(user_id, roll_number, registration_number,
                           course, branch, year_of_study, semester,
                           batch_year, date_of_birth, gender,
                           blood_group=None, permanent_address=None,
                           city=None, state=None, pincode=None,
                           parent_name=None, parent_phone=None):
    """Create student profile."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        student_id = cursor.var(oracledb.NUMBER)
        cursor.execute("""
            INSERT INTO students (
                student_id, user_id, roll_number, registration_number, course, branch,
                year_of_study, semester, batch_year, date_of_birth, gender, blood_group,
                permanent_address, city, state, pincode, parent_name, parent_phone,
                hostel_status, created_at
            ) VALUES (
                seq_students.NEXTVAL, :user_id, :roll_number, :registration_number,
                :course, :branch, :year_of_study, :semester, :batch_year, :date_of_birth,
                :gender, :blood_group, :permanent_address, :city, :state, :pincode,
                :parent_name, :parent_phone, 'PENDING', CURRENT_TIMESTAMP
            )
            RETURNING student_id INTO :student_id
        """, {
            'user_id': user_id,
            'roll_number': roll_number,
            'registration_number': registration_number,
            'course': course,
            'branch': branch,
            'year_of_study': year_of_study,
            'semester': semester,
            'batch_year': batch_year,
            'date_of_birth': date_of_birth,
            'gender': gender,
            'blood_group': blood_group,
            'permanent_address': permanent_address,
            'city': city,
            'state': state,
            'pincode': pincode,
            'parent_name': parent_name,
            'parent_phone': parent_phone,
            'student_id': student_id
        })
        conn.commit()
        return int(student_id.getvalue()[0])
    except oracledb.Error:
        conn.rollback()
        raise
    finally:
        cursor.close()


# ============================================
# Room Functions
# ============================================

def get_all_rooms(block_id=None, status=None):
    """Get all rooms with optional filters."""
    query = """
        SELECT r.*, hb.block_name, hb.block_type,
               r.capacity - r.current_occupancy AS available_beds
        FROM rooms r
        JOIN hostel_blocks hb ON r.block_id = hb.block_id
        WHERE 1=1
    """
    params = {}
    if block_id:
        query += " AND r.block_id = :block_id"
        params['block_id'] = block_id
    if status:
        query += " AND r.status = :status"
        params['status'] = status
    query += " ORDER BY hb.block_name, r.floor_number, r.room_number"
    return execute_query(query, params)


def get_available_rooms(gender=None):
    """Get rooms with available beds."""
    params = {}
    if gender:
        query = """
            SELECT r.*, hb.block_name, r.capacity - r.current_occupancy AS available_beds
            FROM rooms r
            JOIN hostel_blocks hb ON r.block_id = hb.block_id
            WHERE r.status IN ('AVAILABLE', 'OCCUPIED')
            AND r.current_occupancy < r.capacity
            AND (hb.block_type = :gender OR hb.block_type = 'COED')
            ORDER BY hb.block_name, r.room_number
        """
        params['gender'] = gender
    else:
        query = "SELECT * FROM vw_room_availability WHERE available_beds > 0"
    return execute_query(query, params)


def get_room_occupants(room_id):
    """Get students occupying a room."""
    query = """
        SELECT s.student_id, s.roll_number, u.first_name, u.last_name, u.email,
               u.phone_number, s.course, s.branch, s.year_of_study
        FROM students s
        JOIN users u ON s.user_id = u.user_id
        WHERE s.room_id = :room_id AND s.hostel_status = 'ALLOCATED'
        ORDER BY s.roll_number
    """
    return execute_query(query, {'room_id': room_id})


# ============================================
# Complaint Functions
# ============================================

def get_student_complaints(student_id, status=None):
    """Get complaints for a student."""
    query = """
        SELECT c.*, cc.category_name
        FROM complaints c
        LEFT JOIN complaint_categories cc ON c.category_id = cc.category_id
        WHERE c.student_id = :student_id
    """
    params = {'student_id': student_id}
    if status:
        query += " AND c.status = :status"
        params['status'] = status
    query += " ORDER BY c.created_at DESC"
    return execute_query(query, params)


def get_complaint_categories():
    """Get all active complaint categories."""
    query = """
        SELECT category_id, category_name, description, priority_level
        FROM complaint_categories
        WHERE is_active = 'Y'
        ORDER BY category_name
    """
    return execute_query(query)


# ============================================
# Fine Functions
# ============================================

def get_student_fines(student_id, status=None):
    """Get fines for a student."""
    query = """
        SELECT f.*, f.amount - f.paid_amount AS balance
        FROM fines f
        WHERE f.student_id = :student_id
    """
    params = {'student_id': student_id}
    if status:
        query += " AND f.status = :status"
        params['status'] = status
    query += " ORDER BY f.created_at DESC"
    return execute_query(query, params)


def get_pending_fine_total(student_id):
    """Get total pending fines for a student."""
    return execute_function('func_pending_fines', [student_id])


# ============================================
# Leave Request Functions
# ============================================

def get_student_leave_requests(student_id, status=None):
    """Get leave requests for a student."""
    query = """
        SELECT lr.*, ua.first_name || ' ' || NVL(ua.last_name, '') AS approved_by_name
        FROM leave_requests lr
        LEFT JOIN users ua ON lr.approved_by = ua.user_id
        WHERE lr.student_id = :student_id
    """
    params = {'student_id': student_id}
    if status:
        query += " AND lr.status = :status"
        params['status'] = status
    query += " ORDER BY lr.created_at DESC"
    return execute_query(query, params)


def create_leave_request(student_id, leave_type, from_date, to_date, reason,
                         destination=None, contact_during_leave=None,
                         parent_contact=None):
    """Create a new leave request."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        leave_id = cursor.var(oracledb.NUMBER)
        cursor.execute("""
            INSERT INTO leave_requests (
                leave_id, leave_number, student_id, leave_type, from_date, to_date,
                reason, destination, contact_during_leave, parent_contact,
                status, created_at
            ) VALUES (
                seq_leave_requests.NEXTVAL,
                'LVE-' || TO_CHAR(SYSDATE, 'YYYYMM') || '-' || LPAD(seq_leave_number.NEXTVAL, 5, '0'),
                :student_id, :leave_type, :from_date, :to_date, :reason, :destination,
                :contact_during_leave, :parent_contact, 'PENDING', CURRENT_TIMESTAMP
            )
            RETURNING leave_id INTO :leave_id
        """, {
            'student_id': student_id,
            'leave_type': leave_type,
            'from_date': from_date,
            'to_date': to_date,
            'reason': reason,
            'destination': destination,
            'contact_during_leave': contact_during_leave,
            'parent_contact': parent_contact,
            'leave_id': leave_id
        })
        conn.commit()
        return int(leave_id.getvalue()[0])
    except oracledb.Error:
        conn.rollback()
        raise
    finally:
        cursor.close()


# ============================================
# Housekeeping Functions
# ============================================

def get_student_housekeeping_requests(student_id, status=None):
    """Get housekeeping requests for a student."""
    query = """
        SELECT hr.*, s.first_name || ' ' || NVL(s.last_name, '') AS staff_name
        FROM housekeeping_requests hr
        LEFT JOIN staff s ON hr.assigned_staff_id = s.staff_id
        WHERE hr.student_id = :student_id
    """
    params = {'student_id': student_id}
    if status:
        query += " AND hr.status = :status"
        params['status'] = status
    query += " ORDER BY hr.created_at DESC"
    return execute_query(query, params)


# ============================================
# Mess Menu Functions
# ============================================

def get_mess_menu(day_of_week=None, block_id=None):
    """Get mess menu."""
    query = """
        SELECT * FROM mess_menu
        WHERE is_active = 'Y'
        AND (block_id IS NULL OR block_id = :block_id)
    """
    params = {'block_id': block_id}
    if day_of_week:
        query += " AND day_of_week = :day_of_week"
        params['day_of_week'] = day_of_week
    query += """
        ORDER BY
            DECODE(day_of_week, 'MONDAY', 1, 'TUESDAY', 2, 'WEDNESDAY', 3,
                                'THURSDAY', 4, 'FRIDAY', 5, 'SATURDAY', 6, 'SUNDAY', 7),
            DECODE(meal_type, 'BREAKFAST', 1, 'LUNCH', 2, 'SNACKS', 3, 'DINNER', 4)
    """
    return execute_query(query, params)


# ============================================
# Notification Functions
# ============================================

def get_user_notifications(user_id, unread_only=False, limit=10):
    """Get notifications for a user."""
    query = """
        SELECT * FROM notifications
        WHERE user_id = :user_id
    """
    params = {'user_id': user_id}
    if unread_only:
        query += " AND is_read = 'N'"
    query += f" ORDER BY created_at DESC FETCH FIRST {limit} ROWS ONLY"
    return execute_query(query, params)


def mark_notification_read(notification_id, user_id):
    """Mark a notification as read."""
    execute_dml("""
        UPDATE notifications
        SET is_read = 'Y', read_at = CURRENT_TIMESTAMP
        WHERE notification_id = :notification_id AND user_id = :user_id
    """, {'notification_id': notification_id, 'user_id': user_id})


def get_unread_notification_count(user_id):
    """Get count of unread notifications."""
    result = execute_query(
        "SELECT COUNT(*) as count FROM notifications WHERE user_id = :user_id AND is_read = 'N'",
        {'user_id': user_id},
        fetch='one'
    )
    return result['count'] if result else 0


# ============================================
# Announcement Functions
# ============================================

def get_active_announcements(target_audience='ALL', block_id=None, limit=10):
    """Get active announcements."""
    query = """
        SELECT a.*, u.first_name || ' ' || NVL(u.last_name, '') AS created_by_name
        FROM announcements a
        LEFT JOIN users u ON a.created_by = u.user_id
        WHERE a.is_active = 'Y'
        AND a.start_date <= SYSDATE
        AND (a.end_date IS NULL OR a.end_date >= SYSDATE)
        AND (a.target_audience = 'ALL' OR a.target_audience = :target_audience)
        AND (a.target_block_id IS NULL OR a.target_block_id = :block_id)
        ORDER BY a.is_pinned DESC, a.priority DESC, a.created_at DESC
    """
    params = {'target_audience': target_audience, 'block_id': block_id}
    if limit:
        query += f" FETCH FIRST {limit} ROWS ONLY"
    return execute_query(query, params)


# ============================================
# Compatibility Functions
# ============================================

def get_compatibility_questions():
    """Get all active compatibility questions."""
    query = """
        SELECT * FROM compatibility_questions
        WHERE is_active = 'Y'
        ORDER BY display_order, question_id
    """
    return execute_query(query)


def get_student_compatibility_responses(student_id):
    """Get compatibility responses for a student."""
    query = """
        SELECT cr.*, cq.category, cq.question_text
        FROM compatibility_responses cr
        JOIN compatibility_questions cq ON cr.question_id = cq.question_id
        WHERE cr.student_id = :student_id
        ORDER BY cq.display_order
    """
    return execute_query(query, {'student_id': student_id})


def calculate_compatibility(student1_id, student2_id):
    """Calculate compatibility score between two students."""
    return execute_function('func_calculate_compatibility', [student1_id, student2_id])


def get_best_roommate_matches(student_id, limit=5):
    """Get best roommate matches for a student."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        result_cursor = cursor.callfunc(
            'pkg_compatibility.get_best_matches',
            oracledb.CURSOR,
            [student_id, limit]
        )
        columns = [desc[0].lower() for desc in result_cursor.description]
        return [dict(zip(columns, row)) for row in result_cursor]
    finally:
        cursor.close()


# ============================================
# Warden Functions
# ============================================

def get_warden_by_user_id(user_id):
    """Get warden profile by user ID."""
    query = """
        SELECT w.*, u.email, u.phone_number, u.first_name, u.last_name,
               hb.block_name, hb.block_type
        FROM wardens w
        JOIN users u ON w.user_id = u.user_id
        LEFT JOIN hostel_blocks hb ON w.assigned_block_id = hb.block_id
        WHERE w.user_id = :user_id
    """
    return execute_query(query, {'user_id': user_id}, fetch='one')


def get_warden_dashboard_data(warden_id):
    """Get warden dashboard summary."""
    query = "SELECT * FROM vw_warden_dashboard WHERE warden_id = :warden_id"
    return execute_query(query, {'warden_id': warden_id}, fetch='one')


def get_block_students(block_id, status=None, search=None):
    """Get all students in a block."""
    query = """
        SELECT s.*, u.first_name, u.last_name, u.email, u.phone_number,
               r.room_number, r.room_type
        FROM students s
        JOIN users u ON s.user_id = u.user_id
        JOIN rooms r ON s.room_id = r.room_id
        WHERE r.block_id = :block_id
    """
    params = {'block_id': block_id}
    if status:
        query += " AND s.hostel_status = :status"
        params['status'] = status
    if search:
        query += """
            AND (LOWER(u.first_name) LIKE LOWER(:search)
            OR LOWER(u.last_name) LIKE LOWER(:search)
            OR LOWER(s.roll_number) LIKE LOWER(:search))
        """
        params['search'] = f'%{search}%'
    query += " ORDER BY r.room_number, s.roll_number"
    return execute_query(query, params)


def get_block_complaints(block_id, status=None):
    """Get complaints from a block."""
    query = """
        SELECT c.*, s.roll_number, u.first_name, u.last_name, r.room_number,
               cc.category_name
        FROM complaints c
        JOIN students s ON c.student_id = s.student_id
        JOIN users u ON s.user_id = u.user_id
        LEFT JOIN rooms r ON s.room_id = r.room_id
        LEFT JOIN complaint_categories cc ON c.category_id = cc.category_id
        WHERE r.block_id = :block_id
    """
    params = {'block_id': block_id}
    if status:
        query += " AND c.status = :status"
        params['status'] = status
    query += " ORDER BY c.created_at DESC"
    return execute_query(query, params)


def get_block_leave_requests(block_id, status=None):
    """Get leave requests from a block."""
    query = """
        SELECT lr.*, s.roll_number, u.first_name, u.last_name, r.room_number
        FROM leave_requests lr
        JOIN students s ON lr.student_id = s.student_id
        JOIN users u ON s.user_id = u.user_id
        LEFT JOIN rooms r ON s.room_id = r.room_id
        WHERE r.block_id = :block_id
    """
    params = {'block_id': block_id}
    if status:
        query += " AND lr.status = :status"
        params['status'] = status
    query += " ORDER BY lr.created_at DESC"
    return execute_query(query, params)


# ============================================
# Admin Functions
# ============================================

def get_all_students(status=None, search=None, page=1, per_page=20):
    """Get all students with pagination."""
    offset = (page - 1) * per_page
    query = """
        SELECT s.*, u.first_name, u.last_name, u.email, u.phone_number,
               r.room_number, hb.block_name
        FROM students s
        JOIN users u ON s.user_id = u.user_id
        LEFT JOIN rooms r ON s.room_id = r.room_id
        LEFT JOIN hostel_blocks hb ON r.block_id = hb.block_id
        WHERE 1=1
    """
    params = {}
    if status:
        query += " AND s.hostel_status = :status"
        params['status'] = status
    if search:
        query += """
            AND (LOWER(u.first_name) LIKE LOWER(:search)
            OR LOWER(u.last_name) LIKE LOWER(:search)
            OR LOWER(s.roll_number) LIKE LOWER(:search)
            OR LOWER(u.email) LIKE LOWER(:search))
        """
        params['search'] = f'%{search}%'
    query += f" ORDER BY s.roll_number OFFSET {offset} ROWS FETCH NEXT {per_page} ROWS ONLY"
    return execute_query(query, params)


def get_all_hostel_blocks():
    """Get all hostel blocks."""
    query = """
        SELECT hb.*,
               w.warden_id,
               u.first_name || ' ' || NVL(u.last_name, '') AS warden_name,
               (SELECT COUNT(*) FROM rooms r WHERE r.block_id = hb.block_id) AS total_rooms,
               (SELECT NVL(SUM(r.capacity), 0) FROM rooms r WHERE r.block_id = hb.block_id) AS total_capacity,
               (SELECT NVL(SUM(r.current_occupancy), 0) FROM rooms r WHERE r.block_id = hb.block_id) AS current_occupancy
        FROM hostel_blocks hb
        LEFT JOIN wardens w ON hb.warden_id = w.warden_id
        LEFT JOIN users u ON w.user_id = u.user_id
        ORDER BY hb.block_name
    """
    return execute_query(query)


def get_all_wardens():
    """Get all wardens."""
    query = """
        SELECT w.*, u.first_name, u.last_name, u.email, u.phone_number,
               hb.block_name
        FROM wardens w
        JOIN users u ON w.user_id = u.user_id
        LEFT JOIN hostel_blocks hb ON w.assigned_block_id = hb.block_id
        ORDER BY u.first_name
    """
    return execute_query(query)


def get_all_staff(staff_type=None):
    """Get all staff."""
    query = """
        SELECT s.*, hb.block_name
        FROM staff s
        LEFT JOIN hostel_blocks hb ON s.assigned_block_id = hb.block_id
        WHERE 1=1
    """
    params = {}
    if staff_type:
        query += " AND s.staff_type = :staff_type"
        params['staff_type'] = staff_type
    query += " ORDER BY s.first_name"
    return execute_query(query, params)


def get_occupancy_stats():
    """Get overall hostel occupancy statistics."""
    return execute_query("SELECT * FROM vw_hostel_occupancy_stats ORDER BY block_name")


def get_complaint_statistics(days=30):
    """Get complaint statistics for analytics."""
    query = """
        SELECT cc.category_name,
               COUNT(*) AS total,
               SUM(CASE WHEN c.status = 'RESOLVED' THEN 1 ELSE 0 END) AS resolved,
               SUM(CASE WHEN c.status = 'PENDING' THEN 1 ELSE 0 END) AS pending
        FROM complaints c
        LEFT JOIN complaint_categories cc ON c.category_id = cc.category_id
        WHERE c.created_at >= SYSDATE - :days
        GROUP BY cc.category_name
        ORDER BY total DESC
    """
    return execute_query(query, {'days': days})


def get_monthly_stats():
    """Get monthly statistics."""
    return execute_query("SELECT * FROM vw_monthly_analytics", fetch='one')