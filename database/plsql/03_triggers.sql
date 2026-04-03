-- ============================================
-- HOSTEL MANAGEMENT SYSTEM - TRIGGERS
-- Oracle PL/SQL Triggers
-- ============================================
-- ============================================
-- TRIGGER: Update Room Occupancy on Student Insert/Update
-- Automatically updates room occupancy when students are assigned/unassigned
-- ============================================
CREATE OR REPLACE TRIGGER trg_update_room_occupancy
AFTER INSERT OR UPDATE OR DELETE ON students
FOR EACH ROW
DECLARE
    v_old_room_id NUMBER;
    v_new_room_id NUMBER;
BEGIN
    IF INSERTING THEN
        v_new_room_id := :NEW.room_id;
        v_old_room_id := NULL;
    ELSIF UPDATING THEN
        v_old_room_id := :OLD.room_id;
        v_new_room_id := :NEW.room_id;
    ELSIF DELETING THEN
        v_old_room_id := :OLD.room_id;
        v_new_room_id := NULL;
    END IF;
    
    -- Decrease occupancy for old room
    IF v_old_room_id IS NOT NULL THEN
        UPDATE rooms
        SET current_occupancy = GREATEST(current_occupancy - 1, 0),
            status = CASE 
                WHEN current_occupancy - 1 = 0 THEN 'AVAILABLE'
                ELSE 'OCCUPIED'
            END,
            updated_at = CURRENT_TIMESTAMP
        WHERE room_id = v_old_room_id;
    END IF;
    
    -- Increase occupancy for new room
    IF v_new_room_id IS NOT NULL THEN
        UPDATE rooms
        SET current_occupancy = current_occupancy + 1,
            status = CASE 
                WHEN current_occupancy + 1 >= capacity THEN 'FULL'
                ELSE 'OCCUPIED'
            END,
            updated_at = CURRENT_TIMESTAMP
        WHERE room_id = v_new_room_id;
    END IF;
END trg_update_room_occupancy;
/
-- ============================================
-- TRIGGER: Prevent Room Over-allocation
-- Ensures room capacity is never exceeded
-- ============================================
CREATE OR REPLACE TRIGGER trg_check_room_capacity
BEFORE UPDATE ON rooms
FOR EACH ROW
BEGIN
    IF :NEW.current_occupancy > :NEW.capacity THEN
        RAISE_APPLICATION_ERROR(-20001, 
            'Cannot exceed room capacity. Current occupancy (' || 
            :NEW.current_occupancy || ') exceeds capacity (' || :NEW.capacity || ')');
    END IF;
    
    -- Prevent negative occupancy
    IF :NEW.current_occupancy < 0 THEN
        :NEW.current_occupancy := 0;
    END IF;
END trg_check_room_capacity;
/
-- ============================================
-- TRIGGER: Auto-generate Complaint Number
-- Generates unique complaint number before insert
-- ============================================
CREATE OR REPLACE TRIGGER trg_generate_complaint_number
BEFORE INSERT ON complaints
FOR EACH ROW
BEGIN
    IF :NEW.complaint_id IS NULL THEN
        :NEW.complaint_id := seq_complaints.NEXTVAL;
    END IF;
    
    IF :NEW.complaint_number IS NULL THEN
        :NEW.complaint_number := 'CMP-' || TO_CHAR(SYSDATE, 'YYYYMM') || '-' || 
                                 LPAD(seq_complaint_number.NEXTVAL, 5, '0');
    END IF;
    
    :NEW.created_at := CURRENT_TIMESTAMP;
END trg_generate_complaint_number;
/
-- ============================================
-- TRIGGER: Auto-generate Fine Number
-- Generates unique fine number before insert
-- ============================================
CREATE OR REPLACE TRIGGER trg_generate_fine_number
BEFORE INSERT ON fines
FOR EACH ROW
BEGIN
    IF :NEW.fine_id IS NULL THEN
        :NEW.fine_id := seq_fines.NEXTVAL;
    END IF;
    
    IF :NEW.fine_number IS NULL THEN
        :NEW.fine_number := 'FIN-' || TO_CHAR(SYSDATE, 'YYYYMM') || '-' || 
                            LPAD(seq_fine_number.NEXTVAL, 5, '0');
    END IF;
    
    :NEW.created_at := CURRENT_TIMESTAMP;
END trg_generate_fine_number;
/
-- ============================================
-- TRIGGER: Auto-generate Leave Request Number
-- ============================================
CREATE OR REPLACE TRIGGER trg_generate_leave_number
BEFORE INSERT ON leave_requests
FOR EACH ROW
BEGIN
    IF :NEW.leave_id IS NULL THEN
        :NEW.leave_id := seq_leave_requests.NEXTVAL;
    END IF;
    
    IF :NEW.leave_number IS NULL THEN
        :NEW.leave_number := 'LVE-' || TO_CHAR(SYSDATE, 'YYYYMM') || '-' || 
                             LPAD(seq_leave_number.NEXTVAL, 5, '0');
    END IF;
    
    :NEW.created_at := CURRENT_TIMESTAMP;
END trg_generate_leave_number;
/
-- ============================================
-- TRIGGER: Auto-generate Housekeeping Request Number
-- ============================================
CREATE OR REPLACE TRIGGER trg_generate_hk_number
BEFORE INSERT ON housekeeping_requests
FOR EACH ROW
BEGIN
    IF :NEW.request_id IS NULL THEN
        :NEW.request_id := seq_housekeeping_requests.NEXTVAL;
    END IF;
    
    IF :NEW.request_number IS NULL THEN
        :NEW.request_number := 'HK-' || TO_CHAR(SYSDATE, 'YYYYMM') || '-' || 
                               LPAD(seq_hk_request_number.NEXTVAL, 5, '0');
    END IF;
    
    :NEW.created_at := CURRENT_TIMESTAMP;
END trg_generate_hk_number;
/
-- ============================================
-- TRIGGER: Log Complaint Status Changes
-- Creates audit log entry when complaint status changes
-- ============================================
CREATE OR REPLACE TRIGGER trg_log_complaint_status
AFTER UPDATE OF status ON complaints
FOR EACH ROW
DECLARE
    v_user_id NUMBER;
BEGIN
    -- Get the student's user_id
    SELECT user_id INTO v_user_id
    FROM students WHERE student_id = :NEW.student_id;
    
    INSERT INTO audit_log (
        log_id, user_id, action_type, table_name, record_id,
        old_values, new_values, action_timestamp
    ) VALUES (
        seq_audit_log.NEXTVAL,
        NULL,  -- System action
        'COMPLAINT_STATUS_CHANGE',
        'COMPLAINTS',
        :NEW.complaint_id,
        '{"status": "' || :OLD.status || '"}',
        '{"status": "' || :NEW.status || '", "assigned_to": ' || NVL(TO_CHAR(:NEW.assigned_to), 'null') || '}',
        CURRENT_TIMESTAMP
    );
END trg_log_complaint_status;
/
-- ============================================
-- TRIGGER: Update Fine Status on Due Date
-- Marks overdue fines
-- ============================================
CREATE OR REPLACE TRIGGER trg_update_fine_status
BEFORE UPDATE ON fines
FOR EACH ROW
BEGIN
    -- Check if fine is overdue
    IF :NEW.due_date < SYSDATE AND :NEW.status = 'PENDING' THEN
        :NEW.status := 'OVERDUE';
    END IF;
    
    -- Check if fully paid
    IF :NEW.paid_amount >= :NEW.amount AND :NEW.status NOT IN ('PAID', 'WAIVED') THEN
        :NEW.status := 'PAID';
    END IF;
    
    :NEW.updated_at := CURRENT_TIMESTAMP;
END trg_update_fine_status;
/
-- ============================================
-- TRIGGER: Prevent Duplicate Active Room Assignment
-- Ensures a student has only one active room allocation
-- ============================================
CREATE OR REPLACE TRIGGER trg_prevent_duplicate_allocation
BEFORE INSERT ON room_allocations
FOR EACH ROW
DECLARE
    v_active_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_active_count
    FROM room_allocations
    WHERE student_id = :NEW.student_id
    AND status = 'ACTIVE';
    
    IF v_active_count > 0 AND :NEW.status = 'ACTIVE' THEN
        RAISE_APPLICATION_ERROR(-20002, 
            'Student already has an active room allocation. Deallocate first.');
    END IF;
END trg_prevent_duplicate_allocation;
/
-- ============================================
-- TRIGGER: Update Timestamps on Tables
-- Auto-update updated_at timestamp
-- ============================================
CREATE OR REPLACE TRIGGER trg_students_timestamp
BEFORE UPDATE ON students
FOR EACH ROW
BEGIN
    :NEW.updated_at := CURRENT_TIMESTAMP;
END;
/
CREATE OR REPLACE TRIGGER trg_rooms_timestamp
BEFORE UPDATE ON rooms
FOR EACH ROW
BEGIN
    :NEW.updated_at := CURRENT_TIMESTAMP;
END;
/
CREATE OR REPLACE TRIGGER trg_users_timestamp
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    :NEW.updated_at := CURRENT_TIMESTAMP;
END;
/
CREATE OR REPLACE TRIGGER trg_complaints_timestamp
BEFORE UPDATE ON complaints
FOR EACH ROW
BEGIN
    :NEW.updated_at := CURRENT_TIMESTAMP;
END;
/
-- ============================================
-- TRIGGER: Expire Leave Requests
-- Automatically expires pending leave requests past the from_date
-- ============================================
CREATE OR REPLACE TRIGGER trg_expire_leave_requests
BEFORE UPDATE ON leave_requests
FOR EACH ROW
BEGIN
    IF :OLD.status = 'PENDING' AND :OLD.from_date < SYSDATE THEN
        :NEW.status := 'EXPIRED';
    END IF;
END;
/
-- ============================================
-- TRIGGER: Create Notification on New Announcement
-- ============================================
CREATE OR REPLACE TRIGGER trg_announcement_notification
AFTER INSERT ON announcements
FOR EACH ROW
BEGIN
    -- Insert notifications for all relevant users
    IF :NEW.target_audience = 'ALL' OR :NEW.target_audience = 'STUDENTS' THEN
        INSERT INTO notifications (
            notification_id, user_id, title, message, notification_type,
            reference_type, reference_id, created_at
        )
        SELECT seq_notifications.NEXTVAL, s.user_id,
               'New Announcement: ' || :NEW.title,
               DBMS_LOB.SUBSTR(:NEW.content, 200, 1),
               CASE :NEW.priority WHEN 'CRITICAL' THEN 'WARNING' ELSE 'INFO' END,
               'ANNOUNCEMENT', :NEW.announcement_id, CURRENT_TIMESTAMP
        FROM students s
        WHERE :NEW.target_block_id IS NULL 
           OR s.room_id IN (SELECT room_id FROM rooms WHERE block_id = :NEW.target_block_id);
    END IF;
END;
/
-- ============================================
-- TRIGGER: Validate Leave Request Dates
-- ============================================
CREATE OR REPLACE TRIGGER trg_validate_leave_dates
BEFORE INSERT OR UPDATE ON leave_requests
FOR EACH ROW
BEGIN
    IF :NEW.to_date < :NEW.from_date THEN
        RAISE_APPLICATION_ERROR(-20003, 'End date cannot be before start date.');
    END IF;
    
    IF :NEW.from_date < TRUNC(SYSDATE) AND :NEW.status = 'PENDING' THEN
        RAISE_APPLICATION_ERROR(-20004, 'Cannot create leave request for past dates.');
    END IF;
END;
/
