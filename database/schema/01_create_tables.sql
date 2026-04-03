-- ============================================
-- HOSTEL MANAGEMENT SYSTEM - DATABASE SCHEMA
-- Oracle SQL Database Tables
-- ============================================
-- Drop existing tables (in reverse dependency order)
BEGIN
    FOR t IN (SELECT table_name FROM user_tables WHERE table_name IN (
        'AUDIT_LOG', 'NOTIFICATIONS', 'ANNOUNCEMENTS', 'COMPATIBILITY_RESPONSES',
        'COMPATIBILITY_QUESTIONS', 'VISITOR_LOG', 'HOUSEKEEPING_REQUESTS',
        'LEAVE_REQUESTS', 'FINE_PAYMENTS', 'FINES', 'COMPLAINTS', 'COMPLAINT_CATEGORIES',
        'ROOM_ALLOCATIONS', 'MESS_MENU', 'STAFF', 'STUDENTS', 'USERS', 'ROOMS',
        'HOSTEL_BLOCKS', 'WARDENS'
    )) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
    END LOOP;
END;
/
-- ============================================
-- HOSTEL BLOCKS TABLE
-- Stores information about hostel buildings
-- ============================================
CREATE TABLE hostel_blocks (
    block_id            NUMBER(10) PRIMARY KEY,
    block_name          VARCHAR2(100) NOT NULL UNIQUE,
    block_type          VARCHAR2(20) CHECK (block_type IN ('MALE', 'FEMALE', 'COED')),
    total_floors        NUMBER(3) DEFAULT 1,
    total_rooms         NUMBER(5) DEFAULT 0,
    warden_id           NUMBER(10),
    address             VARCHAR2(500),
    contact_number      VARCHAR2(20),
    facilities          VARCHAR2(1000),
    status              VARCHAR2(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'MAINTENANCE')),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- ============================================
-- ROOMS TABLE
-- Stores hostel room information
-- ============================================
CREATE TABLE rooms (
    room_id             NUMBER(10) PRIMARY KEY,
    room_number         VARCHAR2(20) NOT NULL,
    block_id            NUMBER(10) NOT NULL,
    floor_number        NUMBER(3) NOT NULL,
    room_type           VARCHAR2(30) CHECK (room_type IN ('SINGLE', 'DOUBLE', 'TRIPLE', 'QUAD', 'DORMITORY')),
    capacity            NUMBER(2) NOT NULL,
    current_occupancy   NUMBER(2) DEFAULT 0,
    rent_amount         NUMBER(10, 2) DEFAULT 0,
    amenities           VARCHAR2(500),
    status              VARCHAR2(20) DEFAULT 'AVAILABLE' CHECK (status IN ('AVAILABLE', 'OCCUPIED', 'FULL', 'MAINTENANCE', 'RESERVED')),
    ac_available        CHAR(1) DEFAULT 'N' CHECK (ac_available IN ('Y', 'N')),
    attached_bathroom   CHAR(1) DEFAULT 'N' CHECK (attached_bathroom IN ('Y', 'N')),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_room_block FOREIGN KEY (block_id) REFERENCES hostel_blocks(block_id),
    CONSTRAINT uk_room_block UNIQUE (room_number, block_id),
    CONSTRAINT chk_occupancy CHECK (current_occupancy <= capacity)
);
-- ============================================
-- USERS TABLE
-- Base table for all system users
-- ============================================
CREATE TABLE users (
    user_id             NUMBER(10) PRIMARY KEY,
    username            VARCHAR2(50) NOT NULL UNIQUE,
    email               VARCHAR2(100) NOT NULL UNIQUE,
    password_hash       VARCHAR2(255) NOT NULL,
    role                VARCHAR2(20) NOT NULL CHECK (role IN ('STUDENT', 'WARDEN', 'ADMIN')),
    first_name          VARCHAR2(100) NOT NULL,
    last_name           VARCHAR2(100),
    phone_number        VARCHAR2(20),
    profile_image       VARCHAR2(500),
    is_active           CHAR(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N')),
    last_login          TIMESTAMP,
    password_reset_token VARCHAR2(255),
    token_expiry        TIMESTAMP,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- ============================================
-- WARDENS TABLE
-- Extended information for warden users
-- ============================================
CREATE TABLE wardens (
    warden_id           NUMBER(10) PRIMARY KEY,
    user_id             NUMBER(10) NOT NULL UNIQUE,
    employee_id         VARCHAR2(50) NOT NULL UNIQUE,
    department          VARCHAR2(100),
    designation         VARCHAR2(100),
    joining_date        DATE,
    qualification       VARCHAR2(200),
    experience_years    NUMBER(3),
    assigned_block_id   NUMBER(10),
    office_location     VARCHAR2(200),
    emergency_contact   VARCHAR2(20),
    status              VARCHAR2(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'ON_LEAVE')),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_warden_user FOREIGN KEY (user_id) REFERENCES users(user_id),
    CONSTRAINT fk_warden_block FOREIGN KEY (assigned_block_id) REFERENCES hostel_blocks(block_id)
);
-- Add foreign key for warden in hostel_blocks after wardens table is created
ALTER TABLE hostel_blocks ADD CONSTRAINT fk_block_warden FOREIGN KEY (warden_id) REFERENCES wardens(warden_id);
-- ============================================
-- STUDENTS TABLE
-- Extended information for student users
-- ============================================
CREATE TABLE students (
    student_id          NUMBER(10) PRIMARY KEY,
    user_id             NUMBER(10) NOT NULL UNIQUE,
    roll_number         VARCHAR2(50) NOT NULL UNIQUE,
    registration_number VARCHAR2(50) UNIQUE,
    course              VARCHAR2(100),
    branch              VARCHAR2(100),
    year_of_study       NUMBER(1) CHECK (year_of_study BETWEEN 1 AND 6),
    semester            NUMBER(2),
    batch_year          NUMBER(4),
    date_of_birth       DATE,
    gender              VARCHAR2(10) CHECK (gender IN ('MALE', 'FEMALE', 'OTHER')),
    blood_group         VARCHAR2(5),
    nationality         VARCHAR2(50) DEFAULT 'Indian',
    permanent_address   VARCHAR2(500),
    city                VARCHAR2(100),
    state               VARCHAR2(100),
    pincode             VARCHAR2(10),
    parent_name         VARCHAR2(200),
    parent_phone        VARCHAR2(20),
    parent_email        VARCHAR2(100),
    emergency_contact   VARCHAR2(20),
    room_id             NUMBER(10),
    admission_date      DATE,
    hostel_join_date    DATE,
    hostel_status       VARCHAR2(20) DEFAULT 'PENDING' CHECK (hostel_status IN ('PENDING', 'ALLOCATED', 'CHECKED_OUT', 'SUSPENDED')),
    compatibility_completed CHAR(1) DEFAULT 'N' CHECK (compatibility_completed IN ('Y', 'N')),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_student_user FOREIGN KEY (user_id) REFERENCES users(user_id),
    CONSTRAINT fk_student_room FOREIGN KEY (room_id) REFERENCES rooms(room_id)
);
-- ============================================
-- STAFF TABLE
-- Hostel staff information (housekeeping, security, etc.)
-- ============================================
CREATE TABLE staff (
    staff_id            NUMBER(10) PRIMARY KEY,
    employee_id         VARCHAR2(50) NOT NULL UNIQUE,
    first_name          VARCHAR2(100) NOT NULL,
    last_name           VARCHAR2(100),
    staff_type          VARCHAR2(50) CHECK (staff_type IN ('HOUSEKEEPING', 'SECURITY', 'MAINTENANCE', 'MESS', 'ADMIN', 'OTHER')),
    phone_number        VARCHAR2(20),
    email               VARCHAR2(100),
    address             VARCHAR2(500),
    assigned_block_id   NUMBER(10),
    shift               VARCHAR2(20) CHECK (shift IN ('MORNING', 'AFTERNOON', 'NIGHT', 'ROTATING')),
    joining_date        DATE,
    salary              NUMBER(10, 2),
    status              VARCHAR2(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'ON_LEAVE')),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_staff_block FOREIGN KEY (assigned_block_id) REFERENCES hostel_blocks(block_id)
);
-- ============================================
-- MESS MENU TABLE
-- Weekly mess menu management
-- ============================================
CREATE TABLE mess_menu (
    menu_id             NUMBER(10) PRIMARY KEY,
    day_of_week         VARCHAR2(15) NOT NULL CHECK (day_of_week IN ('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY')),
    meal_type           VARCHAR2(20) NOT NULL CHECK (meal_type IN ('BREAKFAST', 'LUNCH', 'SNACKS', 'DINNER')),
    menu_items          VARCHAR2(1000) NOT NULL,
    timing_start        VARCHAR2(10),
    timing_end          VARCHAR2(10),
    special_diet        VARCHAR2(500),
    block_id            NUMBER(10),
    is_active           CHAR(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N')),
    effective_date      DATE DEFAULT SYSDATE,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_menu_block FOREIGN KEY (block_id) REFERENCES hostel_blocks(block_id),
    CONSTRAINT uk_mess_menu UNIQUE (day_of_week, meal_type, block_id, effective_date)
);
-- ============================================
-- ROOM ALLOCATIONS TABLE
-- Tracks room allocation history
-- ============================================
CREATE TABLE room_allocations (
    allocation_id       NUMBER(10) PRIMARY KEY,
    student_id          NUMBER(10) NOT NULL,
    room_id             NUMBER(10) NOT NULL,
    allocation_date     DATE NOT NULL,
    checkout_date       DATE,
    allocation_type     VARCHAR2(20) DEFAULT 'REGULAR' CHECK (allocation_type IN ('REGULAR', 'TEMPORARY', 'TRANSFER', 'EXCHANGE')),
    allocated_by        NUMBER(10),
    status              VARCHAR2(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'COMPLETED', 'CANCELLED', 'TRANSFERRED')),
    remarks             VARCHAR2(500),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_alloc_student FOREIGN KEY (student_id) REFERENCES students(student_id),
    CONSTRAINT fk_alloc_room FOREIGN KEY (room_id) REFERENCES rooms(room_id),
    CONSTRAINT fk_alloc_by FOREIGN KEY (allocated_by) REFERENCES users(user_id)
);
-- ============================================
-- COMPLAINT CATEGORIES TABLE
-- Categories for complaint classification
-- ============================================
CREATE TABLE complaint_categories (
    category_id         NUMBER(10) PRIMARY KEY,
    category_name       VARCHAR2(100) NOT NULL UNIQUE,
    description         VARCHAR2(500),
    priority_level      VARCHAR2(20) DEFAULT 'MEDIUM' CHECK (priority_level IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    resolution_sla_hours NUMBER(5) DEFAULT 48,
    is_active           CHAR(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N')),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- ============================================
-- COMPLAINTS TABLE
-- Student complaints and grievances
-- ============================================
CREATE TABLE complaints (
    complaint_id        NUMBER(10) PRIMARY KEY,
    complaint_number    VARCHAR2(50) NOT NULL UNIQUE,
    student_id          NUMBER(10) NOT NULL,
    category_id         NUMBER(10),
    subject             VARCHAR2(200) NOT NULL,
    description         CLOB NOT NULL,
    priority            VARCHAR2(20) DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    status              VARCHAR2(30) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED', 'CLOSED', 'REJECTED')),
    assigned_to         NUMBER(10),
    room_id             NUMBER(10),
    attachment_path     VARCHAR2(500),
    resolution_notes    CLOB,
    resolved_by         NUMBER(10),
    resolved_at         TIMESTAMP,
    feedback_rating     NUMBER(1) CHECK (feedback_rating BETWEEN 1 AND 5),
    feedback_comments   VARCHAR2(500),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_complaint_student FOREIGN KEY (student_id) REFERENCES students(student_id),
    CONSTRAINT fk_complaint_category FOREIGN KEY (category_id) REFERENCES complaint_categories(category_id),
    CONSTRAINT fk_complaint_assigned FOREIGN KEY (assigned_to) REFERENCES users(user_id),
    CONSTRAINT fk_complaint_room FOREIGN KEY (room_id) REFERENCES rooms(room_id),
    CONSTRAINT fk_complaint_resolved FOREIGN KEY (resolved_by) REFERENCES users(user_id)
);
-- ============================================
-- FINES TABLE
-- Student fines and penalties
-- ============================================
CREATE TABLE fines (
    fine_id             NUMBER(10) PRIMARY KEY,
    fine_number         VARCHAR2(50) NOT NULL UNIQUE,
    student_id          NUMBER(10) NOT NULL,
    fine_type           VARCHAR2(50) NOT NULL CHECK (fine_type IN ('LATE_ENTRY', 'DAMAGE', 'RULE_VIOLATION', 'MESS_WASTE', 'ELECTRICITY', 'OTHER')),
    amount              NUMBER(10, 2) NOT NULL,
    description         VARCHAR2(500),
    fine_date           DATE DEFAULT SYSDATE,
    due_date            DATE,
    status              VARCHAR2(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PAID', 'WAIVED', 'OVERDUE', 'PARTIALLY_PAID')),
    paid_amount         NUMBER(10, 2) DEFAULT 0,
    imposed_by          NUMBER(10),
    waived_by           NUMBER(10),
    waiver_reason       VARCHAR2(500),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_fine_student FOREIGN KEY (student_id) REFERENCES students(student_id),
    CONSTRAINT fk_fine_imposed FOREIGN KEY (imposed_by) REFERENCES users(user_id),
    CONSTRAINT fk_fine_waived FOREIGN KEY (waived_by) REFERENCES users(user_id),
    CONSTRAINT chk_paid_amount CHECK (paid_amount <= amount)
);
-- ============================================
-- FINE PAYMENTS TABLE
-- Payment history for fines
-- ============================================
CREATE TABLE fine_payments (
    payment_id          NUMBER(10) PRIMARY KEY,
    fine_id             NUMBER(10) NOT NULL,
    payment_amount      NUMBER(10, 2) NOT NULL,
    payment_date        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_method      VARCHAR2(30) CHECK (payment_method IN ('CASH', 'CARD', 'UPI', 'BANK_TRANSFER', 'CHEQUE')),
    transaction_id      VARCHAR2(100),
    receipt_number      VARCHAR2(50),
    received_by         NUMBER(10),
    remarks             VARCHAR2(500),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_payment_fine FOREIGN KEY (fine_id) REFERENCES fines(fine_id),
    CONSTRAINT fk_payment_received FOREIGN KEY (received_by) REFERENCES users(user_id)
);
-- ============================================
-- LEAVE REQUESTS TABLE
-- Student leave and pass applications
-- ============================================
CREATE TABLE leave_requests (
    leave_id            NUMBER(10) PRIMARY KEY,
    leave_number        VARCHAR2(50) NOT NULL UNIQUE,
    student_id          NUMBER(10) NOT NULL,
    leave_type          VARCHAR2(30) NOT NULL CHECK (leave_type IN ('DAY_PASS', 'NIGHT_PASS', 'WEEKEND', 'VACATION', 'EMERGENCY', 'MEDICAL')),
    from_date           DATE NOT NULL,
    to_date             DATE NOT NULL,
    from_time           VARCHAR2(10),
    to_time             VARCHAR2(10),
    reason              VARCHAR2(1000) NOT NULL,
    destination         VARCHAR2(200),
    contact_during_leave VARCHAR2(20),
    parent_contact      VARCHAR2(20),
    supporting_document VARCHAR2(500),
    status              VARCHAR2(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED', 'EXPIRED')),
    approved_by         NUMBER(10),
    approved_at         TIMESTAMP,
    rejection_reason    VARCHAR2(500),
    actual_return_date  DATE,
    actual_return_time  VARCHAR2(10),
    late_return         CHAR(1) DEFAULT 'N' CHECK (late_return IN ('Y', 'N')),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_leave_student FOREIGN KEY (student_id) REFERENCES students(student_id),
    CONSTRAINT fk_leave_approved FOREIGN KEY (approved_by) REFERENCES users(user_id),
    CONSTRAINT chk_leave_dates CHECK (to_date >= from_date)
);
-- ============================================
-- HOUSEKEEPING REQUESTS TABLE
-- Room cleaning and maintenance requests
-- ============================================
CREATE TABLE housekeeping_requests (
    request_id          NUMBER(10) PRIMARY KEY,
    request_number      VARCHAR2(50) NOT NULL UNIQUE,
    student_id          NUMBER(10) NOT NULL,
    room_id             NUMBER(10) NOT NULL,
    service_type        VARCHAR2(50) NOT NULL CHECK (service_type IN ('CLEANING', 'LAUNDRY', 'PEST_CONTROL', 'PLUMBING', 'ELECTRICAL', 'FURNITURE', 'OTHER')),
    description         VARCHAR2(1000),
    preferred_date      DATE,
    preferred_time      VARCHAR2(20),
    urgency             VARCHAR2(20) DEFAULT 'NORMAL' CHECK (urgency IN ('LOW', 'NORMAL', 'HIGH', 'URGENT')),
    status              VARCHAR2(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
    assigned_staff_id   NUMBER(10),
    scheduled_date      DATE,
    scheduled_time      VARCHAR2(20),
    completed_at        TIMESTAMP,
    feedback_rating     NUMBER(1) CHECK (feedback_rating BETWEEN 1 AND 5),
    feedback_comments   VARCHAR2(500),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_hk_student FOREIGN KEY (student_id) REFERENCES students(student_id),
    CONSTRAINT fk_hk_room FOREIGN KEY (room_id) REFERENCES rooms(room_id),
    CONSTRAINT fk_hk_staff FOREIGN KEY (assigned_staff_id) REFERENCES staff(staff_id)
);
-- ============================================
-- VISITOR LOG TABLE
-- Track visitors to hostel
-- ============================================
CREATE TABLE visitor_log (
    visitor_id          NUMBER(10) PRIMARY KEY,
    student_id          NUMBER(10) NOT NULL,
    visitor_name        VARCHAR2(200) NOT NULL,
    visitor_phone       VARCHAR2(20),
    visitor_email       VARCHAR2(100),
    relation            VARCHAR2(50),
    purpose             VARCHAR2(500),
    id_proof_type       VARCHAR2(50),
    id_proof_number     VARCHAR2(100),
    check_in_time       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    check_out_time      TIMESTAMP,
    approved_by         NUMBER(10),
    vehicle_number      VARCHAR2(50),
    remarks             VARCHAR2(500),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_visitor_student FOREIGN KEY (student_id) REFERENCES students(student_id),
    CONSTRAINT fk_visitor_approved FOREIGN KEY (approved_by) REFERENCES users(user_id)
);
-- ============================================
-- COMPATIBILITY QUESTIONS TABLE
-- Questions for roommate compatibility quiz
-- ============================================
CREATE TABLE compatibility_questions (
    question_id         NUMBER(10) PRIMARY KEY,
    category            VARCHAR2(50) NOT NULL,
    question_text       VARCHAR2(500) NOT NULL,
    question_type       VARCHAR2(20) DEFAULT 'SINGLE' CHECK (question_type IN ('SINGLE', 'MULTIPLE', 'SCALE', 'TEXT')),
    options             VARCHAR2(1000),
    weight_percentage   NUMBER(5, 2) DEFAULT 10,
    display_order       NUMBER(3),
    is_active           CHAR(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N')),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- ============================================
-- COMPATIBILITY RESPONSES TABLE
-- Student responses to compatibility quiz
-- ============================================
CREATE TABLE compatibility_responses (
    response_id         NUMBER(10) PRIMARY KEY,
    student_id          NUMBER(10) NOT NULL,
    question_id         NUMBER(10) NOT NULL,
    response_value      VARCHAR2(500) NOT NULL,
    response_score      NUMBER(3),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_resp_student FOREIGN KEY (student_id) REFERENCES students(student_id),
    CONSTRAINT fk_resp_question FOREIGN KEY (question_id) REFERENCES compatibility_questions(question_id),
    CONSTRAINT uk_student_question UNIQUE (student_id, question_id)
);
-- ============================================
-- ANNOUNCEMENTS TABLE
-- System-wide and block-specific announcements
-- ============================================
CREATE TABLE announcements (
    announcement_id     NUMBER(10) PRIMARY KEY,
    title               VARCHAR2(200) NOT NULL,
    content             CLOB NOT NULL,
    announcement_type   VARCHAR2(30) DEFAULT 'GENERAL' CHECK (announcement_type IN ('GENERAL', 'URGENT', 'MAINTENANCE', 'EVENT', 'ACADEMIC', 'MESS')),
    target_audience     VARCHAR2(30) DEFAULT 'ALL' CHECK (target_audience IN ('ALL', 'STUDENTS', 'WARDENS', 'STAFF', 'SPECIFIC_BLOCK')),
    target_block_id     NUMBER(10),
    priority            VARCHAR2(20) DEFAULT 'NORMAL' CHECK (priority IN ('LOW', 'NORMAL', 'HIGH', 'CRITICAL')),
    start_date          DATE DEFAULT SYSDATE,
    end_date            DATE,
    attachment_path     VARCHAR2(500),
    is_pinned           CHAR(1) DEFAULT 'N' CHECK (is_pinned IN ('Y', 'N')),
    is_active           CHAR(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N')),
    created_by          NUMBER(10),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_announce_block FOREIGN KEY (target_block_id) REFERENCES hostel_blocks(block_id),
    CONSTRAINT fk_announce_created FOREIGN KEY (created_by) REFERENCES users(user_id)
);
-- ============================================
-- NOTIFICATIONS TABLE
-- Individual user notifications
-- ============================================
CREATE TABLE notifications (
    notification_id     NUMBER(10) PRIMARY KEY,
    user_id             NUMBER(10) NOT NULL,
    title               VARCHAR2(200) NOT NULL,
    message             VARCHAR2(1000) NOT NULL,
    notification_type   VARCHAR2(30) DEFAULT 'INFO' CHECK (notification_type IN ('INFO', 'WARNING', 'SUCCESS', 'ERROR', 'REMINDER')),
    reference_type      VARCHAR2(50),
    reference_id        NUMBER(10),
    is_read             CHAR(1) DEFAULT 'N' CHECK (is_read IN ('Y', 'N')),
    read_at             TIMESTAMP,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notif_user FOREIGN KEY (user_id) REFERENCES users(user_id)
);
-- ============================================
-- AUDIT LOG TABLE
-- System activity audit trail
-- ============================================
CREATE TABLE audit_log (
    log_id              NUMBER(10) PRIMARY KEY,
    user_id             NUMBER(10),
    action_type         VARCHAR2(50) NOT NULL,
    table_name          VARCHAR2(100),
    record_id           NUMBER(10),
    old_values          CLOB,
    new_values          CLOB,
    ip_address          VARCHAR2(50),
    user_agent          VARCHAR2(500),
    action_timestamp    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES users(user_id)
);
-- ============================================
-- ADD COMMENTS TO TABLES
-- ============================================
COMMENT ON TABLE hostel_blocks IS 'Stores hostel building information';
COMMENT ON TABLE rooms IS 'Stores hostel room details and occupancy';
COMMENT ON TABLE users IS 'Base authentication table for all users';
COMMENT ON TABLE wardens IS 'Extended profile for warden users';
COMMENT ON TABLE students IS 'Extended profile for student users';
COMMENT ON TABLE staff IS 'Hostel staff information';
COMMENT ON TABLE mess_menu IS 'Weekly mess menu management';
COMMENT ON TABLE room_allocations IS 'Room allocation history and tracking';
COMMENT ON TABLE complaints IS 'Student complaints and grievances';
COMMENT ON TABLE fines IS 'Student fines and penalties';
COMMENT ON TABLE leave_requests IS 'Student leave and pass applications';
COMMENT ON TABLE housekeeping_requests IS 'Room service requests';
COMMENT ON TABLE visitor_log IS 'Visitor entry tracking';
COMMENT ON TABLE compatibility_questions IS 'Roommate compatibility questionnaire';
COMMENT ON TABLE compatibility_responses IS 'Student responses to compatibility quiz';
COMMENT ON TABLE announcements IS 'System announcements';
COMMENT ON TABLE notifications IS 'User notifications';
COMMENT ON TABLE audit_log IS 'System activity audit trail';
