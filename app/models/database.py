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

        def convert_lob(value):
            """Convert LOB objects to strings."""
            if hasattr(value, 'read'):
                return value.read()
            return value

        if fetch == 'one' and result:
            return {col: convert_lob(val) for col, val in zip(columns, result)}
        elif fetch == 'all' and result:
            return [{col: convert_lob(val) for col, val in zip(columns, row)} for row in result]
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
    query = """
        SELECT r.room_id, r.room_number, r.block_id, r.floor_number, r.room_type,
               r.capacity, r.current_occupancy, r.rent_amount,
               r.ac_available, r.attached_bathroom, r.amenities, r.status,
               hb.block_name, hb.block_type,
               r.capacity - r.current_occupancy AS available_beds
        FROM rooms r
        JOIN hostel_blocks hb ON r.block_id = hb.block_id
        WHERE r.status IN ('AVAILABLE', 'OCCUPIED')
        AND r.current_occupancy < r.capacity
    """
    params = {}
    if gender:
        query += " AND (hb.block_type = :gender OR hb.block_type = 'COED')"
        params['gender'] = gender
    query += " ORDER BY hb.block_name, r.room_number"
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
                :student_id, :leave_type, TO_DATE(:from_date, 'YYYY-MM-DD'), TO_DATE(:to_date, 'YYYY-MM-DD'), :reason, :destination,
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


def get_all_announcements(is_active=None, announcement_type=None, target_audience=None):
    """Get all announcements for admin management."""
    query = """
        SELECT a.*, u.first_name || ' ' || NVL(u.last_name, '') AS created_by_name,
               hb.block_name AS target_block_name
        FROM announcements a
        LEFT JOIN users u ON a.created_by = u.user_id
        LEFT JOIN hostel_blocks hb ON a.target_block_id = hb.block_id
        WHERE 1=1
    """
    params = {}
    if is_active is not None:
        query += " AND a.is_active = :is_active"
        params['is_active'] = 'Y' if is_active else 'N'
    if announcement_type:
        query += " AND a.announcement_type = :announcement_type"
        params['announcement_type'] = announcement_type
    if target_audience:
        query += " AND a.target_audience = :target_audience"
        params['target_audience'] = target_audience
    query += " ORDER BY a.created_at DESC"
    return execute_query(query, params)


def get_announcement_by_id(announcement_id):
    """Get a single announcement by ID."""
    return execute_query("""
        SELECT a.*, u.first_name || ' ' || NVL(u.last_name, '') AS created_by_name,
               hb.block_name AS target_block_name
        FROM announcements a
        LEFT JOIN users u ON a.created_by = u.user_id
        LEFT JOIN hostel_blocks hb ON a.target_block_id = hb.block_id
        WHERE a.announcement_id = :announcement_id
    """, {'announcement_id': announcement_id}, fetch='one')


def create_announcement(title, content, announcement_type, target_audience,
                        priority, start_date, end_date, is_pinned, created_by,
                        target_block_id=None):
    """Insert a new announcement."""
    execute_dml("""
        INSERT INTO announcements (
            announcement_id, title, content, announcement_type, target_audience,
            target_block_id, priority, start_date, end_date, is_pinned,
            is_active, created_by, created_at, updated_at
        ) VALUES (
            seq_announcements.NEXTVAL, :title, :content, :announcement_type, :target_audience,
            :target_block_id, :priority, TO_DATE(:start_date, 'YYYY-MM-DD'),
            CASE WHEN :end_date IS NOT NULL THEN TO_DATE(:end_date, 'YYYY-MM-DD') ELSE NULL END,
            :is_pinned, 'Y', :created_by, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        )
    """, {
        'title': title,
        'content': content,
        'announcement_type': announcement_type,
        'target_audience': target_audience,
        'target_block_id': target_block_id,
        'priority': priority,
        'start_date': start_date,
        'end_date': end_date if end_date else None,
        'is_pinned': is_pinned,
        'created_by': created_by,
    })


def update_announcement(announcement_id, title, content, announcement_type,
                        target_audience, priority, start_date, end_date,
                        is_pinned, is_active, target_block_id=None):
    """Update an existing announcement."""
    execute_dml("""
        UPDATE announcements SET
            title = :title,
            content = :content,
            announcement_type = :announcement_type,
            target_audience = :target_audience,
            target_block_id = :target_block_id,
            priority = :priority,
            start_date = TO_DATE(:start_date, 'YYYY-MM-DD'),
            end_date = CASE WHEN :end_date IS NOT NULL THEN TO_DATE(:end_date, 'YYYY-MM-DD') ELSE NULL END,
            is_pinned = :is_pinned,
            is_active = :is_active,
            updated_at = CURRENT_TIMESTAMP
        WHERE announcement_id = :announcement_id
    """, {
        'announcement_id': announcement_id,
        'title': title,
        'content': content,
        'announcement_type': announcement_type,
        'target_audience': target_audience,
        'target_block_id': target_block_id,
        'priority': priority,
        'start_date': start_date,
        'end_date': end_date if end_date else None,
        'is_pinned': is_pinned,
        'is_active': is_active,
    })


def delete_announcement(announcement_id):
    """Soft-delete an announcement by marking it inactive."""
    execute_dml("""
        UPDATE announcements SET is_active = 'N', updated_at = CURRENT_TIMESTAMP
        WHERE announcement_id = :announcement_id
    """, {'announcement_id': announcement_id})


# ============================================
# Compatibility Functions
# ============================================

def get_compatibility_questions():
    # Deduplicate by question_text (data may have been inserted multiple times
    # with different question_ids). Pick the row with the lowest question_id
    # for each unique question text.
    query = """
        SELECT question_id, category, question_text,
               question_type, options, weight_percentage, display_order
        FROM (
            SELECT question_id, category, question_text,
                   question_type, options, weight_percentage, display_order,
                   ROW_NUMBER() OVER (
                       PARTITION BY question_text
                       ORDER BY question_id
                   ) AS rn
            FROM compatibility_questions
            WHERE is_active = 'Y'
        )
        WHERE rn = 1
        ORDER BY display_order, question_id
    """
    return execute_query(query)


def get_student_compatibility_responses(student_id):
    """Get compatibility responses for a student.

    Normalises duplicate question rows (same question_text, different question_id)
    by mapping every response to the canonical question_id (lowest id for that
    question text).  This keeps existing_map keys in sync with what
    get_compatibility_questions() returns.
    """
    query = """
        SELECT canonical.question_id,
               cr.student_id,
               cr.response_value,
               cq.category,
               cq.question_text,
               cq.weight_percentage,
               cq.display_order
        FROM compatibility_responses cr
        JOIN compatibility_questions cq
            ON cr.question_id = cq.question_id
        JOIN (
            SELECT question_text, MIN(question_id) AS question_id
            FROM compatibility_questions
            WHERE is_active = 'Y'
            GROUP BY question_text
        ) canonical
            ON cq.question_text = canonical.question_text
        WHERE cr.student_id = :student_id
        ORDER BY cq.display_order, canonical.question_id
    """
    rows = execute_query(query, {'student_id': student_id})
    if not rows:
        return rows

    # Deduplicate: keep only the last response per canonical question_id
    seen = {}
    for row in rows:
        seen[row['question_id']] = row
    return list(seen.values())


def get_student_by_id(student_id):
    """Get student profile by student_id (not user_id)."""
    query = """
        SELECT s.*, u.email, u.phone_number, u.first_name, u.last_name,
               r.room_number, r.room_type, r.floor_number,
               hb.block_name, hb.block_type
        FROM students s
        JOIN users u ON s.user_id = u.user_id
        LEFT JOIN rooms r ON s.room_id = r.room_id
        LEFT JOIN hostel_blocks hb ON r.block_id = hb.block_id
        WHERE s.student_id = :student_id
    """
    return execute_query(query, {'student_id': student_id}, fetch='one')


def get_room_by_id(room_id):
    """Get room details by room_id."""
    query = """
        SELECT r.*, hb.block_name, hb.block_type,
               r.capacity - r.current_occupancy AS available_beds
        FROM rooms r
        JOIN hostel_blocks hb ON r.block_id = hb.block_id
        WHERE r.room_id = :room_id
    """
    return execute_query(query, {'room_id': room_id}, fetch='one')


def get_unallocated_students_for_room(room_id, exclude_student_id):
    """Return PENDING students eligible for the given room's block.
    Includes cgpa and min_pref_rank (lowest preference rank where the student
    listed this block; NULL means no preference for this block).
    """
    query = """
        SELECT s.student_id, s.roll_number, s.course, s.branch,
               s.year_of_study, s.gender, s.compatibility_completed,
               s.cgpa,
               u.first_name, u.last_name, u.email, u.phone_number,
               u.first_name || ' ' || NVL(u.last_name, '') AS full_name,
               (SELECT MIN(rp.preference_rank)
                FROM room_preferences rp
                WHERE rp.student_id = s.student_id
                  AND rp.block_id = hb.block_id) AS min_pref_rank
        FROM students s
        JOIN users u ON s.user_id = u.user_id
        JOIN rooms r ON r.room_id = :room_id
        JOIN hostel_blocks hb ON r.block_id = hb.block_id
        WHERE s.student_id != :exclude_id
        AND s.hostel_status = 'PENDING'
        AND (hb.block_type = 'COED' OR s.gender = hb.block_type)
    """
    return execute_query(query, {'room_id': room_id, 'exclude_id': exclude_student_id})


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

        def convert_lob(value):
            """Convert LOB objects to strings."""
            if hasattr(value, 'read'):
                return value.read()
            return value

        return [{col: convert_lob(val) for col, val in zip(columns, row)} for row in result_cursor]
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


def get_block_housekeeping_requests(block_id, status=None):
    """Get housekeeping requests from a block."""
    query = """
        SELECT hr.*, s.roll_number, u.first_name, u.last_name, r.room_number,
               st.first_name || ' ' || NVL(st.last_name, '') AS staff_name
        FROM housekeeping_requests hr
        JOIN students s ON hr.student_id = s.student_id
        JOIN users u ON s.user_id = u.user_id
        JOIN rooms r ON hr.room_id = r.room_id
        LEFT JOIN staff st ON hr.assigned_staff_id = st.staff_id
        WHERE r.block_id = :block_id
    """
    params = {'block_id': block_id}
    if status:
        query += " AND hr.status = :status"
        params['status'] = status
    query += " ORDER BY hr.created_at DESC"
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


# ============================================
# Mess Menu Admin Functions
# ============================================

def upsert_mess_menu_item(day_of_week, meal_type, menu_items,
                          timing_start, timing_end, special_diet=None, block_id=None):
    """Insert or update a single mess menu row (global menu, block_id=NULL)."""
    execute_dml("""
        MERGE INTO mess_menu mm
        USING dual
        ON (
            mm.day_of_week = :day_of_week
            AND mm.meal_type = :meal_type
            AND (mm.block_id IS NULL AND :block_id IS NULL
                 OR mm.block_id = :block_id)
        )
        WHEN MATCHED THEN
            UPDATE SET
                menu_items   = :menu_items,
                timing_start = :timing_start,
                timing_end   = :timing_end,
                special_diet = :special_diet,
                is_active    = 'Y',
                updated_at   = CURRENT_TIMESTAMP
        WHEN NOT MATCHED THEN
            INSERT (menu_id, day_of_week, meal_type, menu_items,
                    timing_start, timing_end, special_diet, block_id, is_active, effective_date)
            VALUES (seq_mess_menu.NEXTVAL, :day_of_week, :meal_type, :menu_items,
                    :timing_start, :timing_end, :special_diet, :block_id, 'Y', SYSDATE)
    """, {
        'day_of_week': day_of_week,
        'meal_type': meal_type,
        'menu_items': menu_items,
        'timing_start': timing_start,
        'timing_end': timing_end,
        'special_diet': special_diet or None,
        'block_id': block_id,
    })


# ============================================
# CGPA / Block Cutoff Functions
# ============================================

def update_student_cgpa(student_id, cgpa):
    """Set or update CGPA for a student."""
    execute_dml("""
        UPDATE students SET cgpa = :cgpa, updated_at = CURRENT_TIMESTAMP
        WHERE student_id = :student_id
    """, {'student_id': student_id, 'cgpa': cgpa})


def update_block_cgpa_cutoff(block_id, cgpa_cutoff):
    """Set the minimum CGPA required to request a room in this block."""
    execute_dml("""
        UPDATE hostel_blocks SET cgpa_cutoff = :cutoff, updated_at = CURRENT_TIMESTAMP
        WHERE block_id = :block_id
    """, {'block_id': block_id, 'cutoff': cgpa_cutoff})


# ============================================
# Room Preference Functions
# ============================================

def get_student_room_preferences(student_id):
    """Return the student's ranked block preferences with block details."""
    return execute_query("""
        SELECT rp.preference_id, rp.preference_rank, rp.notes,
               hb.block_id, hb.block_name, hb.block_type,
               hb.facilities, hb.cgpa_cutoff,
               (SELECT NVL(SUM(r.capacity) - SUM(r.current_occupancy), 0)
                FROM rooms r WHERE r.block_id = hb.block_id AND r.status != 'MAINTENANCE'
               ) AS available_beds
        FROM room_preferences rp
        JOIN hostel_blocks hb ON rp.block_id = hb.block_id
        WHERE rp.student_id = :student_id
        ORDER BY rp.preference_rank
    """, {'student_id': student_id})


def save_student_room_preferences(student_id, ranked_block_ids, notes_list):
    """Replace a student's preferences with a new ranked list (max 3)."""
    # Delete existing
    execute_dml("DELETE FROM room_preferences WHERE student_id = :sid", {'sid': student_id})
    for rank, (block_id, note) in enumerate(zip(ranked_block_ids, notes_list), start=1):
        if block_id:
            execute_dml("""
                INSERT INTO room_preferences
                    (preference_id, student_id, block_id, preference_rank, notes, created_at, updated_at)
                VALUES
                    (seq_room_preferences.NEXTVAL, :sid, :bid, :rank, :note,
                     CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            """, {'sid': student_id, 'bid': int(block_id), 'rank': rank, 'note': note or None})


def get_allocation_queue():
    """
    All PENDING students ordered by CGPA DESC (nulls last), with their top
    preferred block (highest rank they qualify for based on CGPA cutoff).
    """
    return execute_query("""
        SELECT s.student_id,
               s.roll_number,
               s.course,
               s.branch,
               s.year_of_study,
               s.gender,
               s.cgpa,
               s.compatibility_completed,
               u.first_name,
               u.last_name,
               u.first_name || ' ' || NVL(u.last_name, '') AS full_name,
               u.email,
               -- Rank-1 preference
               p1.block_id    AS pref1_block_id,
               b1.block_name  AS pref1_block_name,
               b1.cgpa_cutoff AS pref1_cutoff,
               -- Rank-2 preference
               p2.block_id    AS pref2_block_id,
               b2.block_name  AS pref2_block_name,
               b2.cgpa_cutoff AS pref2_cutoff,
               -- Rank-3 preference
               p3.block_id    AS pref3_block_id,
               b3.block_name  AS pref3_block_name,
               b3.cgpa_cutoff AS pref3_cutoff
        FROM students s
        JOIN users u ON s.user_id = u.user_id
        LEFT JOIN room_preferences p1 ON p1.student_id = s.student_id AND p1.preference_rank = 1
        LEFT JOIN hostel_blocks b1   ON b1.block_id = p1.block_id
        LEFT JOIN room_preferences p2 ON p2.student_id = s.student_id AND p2.preference_rank = 2
        LEFT JOIN hostel_blocks b2   ON b2.block_id = p2.block_id
        LEFT JOIN room_preferences p3 ON p3.student_id = s.student_id AND p3.preference_rank = 3
        LEFT JOIN hostel_blocks b3   ON b3.block_id = p3.block_id
        WHERE s.hostel_status = 'PENDING'
        ORDER BY s.cgpa DESC NULLS LAST, s.roll_number
    """)