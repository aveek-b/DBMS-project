-- ============================================
-- HOSTEL MANAGEMENT SYSTEM - PROCEDURES
-- Oracle PL/SQL Stored Procedures
-- ============================================
-- ============================================
-- PROCEDURE: Allocate Room to Student
-- Assigns a student to a room with validation
-- ============================================
CREATE OR REPLACE PROCEDURE proc_allocate_room (
    p_student_id    IN NUMBER,
    p_room_id       IN NUMBER,
    p_allocated_by  IN NUMBER,
    p_remarks       IN VARCHAR2 DEFAULT NULL,
    p_result        OUT VARCHAR2,
    p_message       OUT VARCHAR2
)
IS
    v_room_capacity     NUMBER;
    v_current_occupancy NUMBER;
    v_room_status       VARCHAR2(20);
    v_student_status    VARCHAR2(20);
    v_current_room_id   NUMBER;
    v_student_gender    VARCHAR2(10);
    v_block_type        VARCHAR2(20);
    v_allocation_id     NUMBER;
BEGIN
    -- Check if student exists and get current status
    SELECT hostel_status, room_id, gender
    INTO v_student_status, v_current_room_id, v_student_gender
    FROM students
    WHERE student_id = p_student_id;
    
    -- Check if student already has an active room allocation
    IF v_current_room_id IS NOT NULL AND v_student_status = 'ALLOCATED' THEN
        p_result := 'ERROR';
        p_message := 'Student already has an active room allocation. Please deallocate first.';
        RETURN;
    END IF;
    
    -- Get room details
    SELECT capacity, current_occupancy, status
    INTO v_room_capacity, v_current_occupancy, v_room_status
    FROM rooms
    WHERE room_id = p_room_id;
    
    -- Check room availability
    IF v_room_status NOT IN ('AVAILABLE', 'OCCUPIED') THEN
        p_result := 'ERROR';
        p_message := 'Room is not available for allocation. Current status: ' || v_room_status;
        RETURN;
    END IF;
    
    -- Check capacity
    IF v_current_occupancy >= v_room_capacity THEN
        p_result := 'ERROR';
        p_message := 'Room is already at full capacity.';
        RETURN;
    END IF;
    
    -- Check gender compatibility with block
    SELECT hb.block_type
    INTO v_block_type
    FROM rooms r
    JOIN hostel_blocks hb ON r.block_id = hb.block_id
    WHERE r.room_id = p_room_id;
    
    IF v_block_type != 'COED' AND v_block_type != v_student_gender THEN
        p_result := 'ERROR';
        p_message := 'Block type (' || v_block_type || ') does not match student gender (' || v_student_gender || ').';
        RETURN;
    END IF;
    
    -- Perform allocation
    v_allocation_id := seq_room_allocations.NEXTVAL;
    
    INSERT INTO room_allocations (
        allocation_id, student_id, room_id, allocation_date, 
        allocated_by, status, remarks, created_at
    ) VALUES (
        v_allocation_id, p_student_id, p_room_id, SYSDATE,
        p_allocated_by, 'ACTIVE', p_remarks, CURRENT_TIMESTAMP
    );
    
    -- Update student record
    UPDATE students
    SET room_id = p_room_id,
        hostel_status = 'ALLOCATED',
        hostel_join_date = NVL(hostel_join_date, SYSDATE),
        updated_at = CURRENT_TIMESTAMP
    WHERE student_id = p_student_id;
    
    -- Room occupancy is updated by trigger
    
    COMMIT;
    
    p_result := 'SUCCESS';
    p_message := 'Room allocated successfully. Allocation ID: ' || v_allocation_id;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_result := 'ERROR';
        p_message := 'Student or Room not found.';
        ROLLBACK;
    WHEN OTHERS THEN
        p_result := 'ERROR';
        p_message := 'Error: ' || SQLERRM;
        ROLLBACK;
END proc_allocate_room;
/
-- ============================================
-- PROCEDURE: Deallocate Room from Student
-- Removes student from their current room
-- ============================================
CREATE OR REPLACE PROCEDURE proc_deallocate_room (
    p_student_id    IN NUMBER,
    p_remarks       IN VARCHAR2 DEFAULT NULL,
    p_result        OUT VARCHAR2,
    p_message       OUT VARCHAR2
)
IS
    v_room_id       NUMBER;
    v_allocation_id NUMBER;
BEGIN
    -- Get current room assignment
    SELECT room_id INTO v_room_id
    FROM students
    WHERE student_id = p_student_id AND hostel_status = 'ALLOCATED';
    
    IF v_room_id IS NULL THEN
        p_result := 'ERROR';
        p_message := 'Student does not have an active room allocation.';
        RETURN;
    END IF;
    
    -- Get active allocation record
    SELECT allocation_id INTO v_allocation_id
    FROM room_allocations
    WHERE student_id = p_student_id AND room_id = v_room_id AND status = 'ACTIVE'
    ORDER BY allocation_date DESC
    FETCH FIRST 1 ROW ONLY;
    
    -- Update allocation record
    UPDATE room_allocations
    SET status = 'COMPLETED',
        checkout_date = SYSDATE,
        remarks = NVL(remarks, '') || ' | Checkout: ' || NVL(p_remarks, 'Regular checkout'),
        updated_at = CURRENT_TIMESTAMP
    WHERE allocation_id = v_allocation_id;
    
    -- Update student record
    UPDATE students
    SET room_id = NULL,
        hostel_status = 'CHECKED_OUT',
        updated_at = CURRENT_TIMESTAMP
    WHERE student_id = p_student_id;
    
    -- Room occupancy is updated by trigger
    
    COMMIT;
    
    p_result := 'SUCCESS';
    p_message := 'Room deallocated successfully.';
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_result := 'ERROR';
        p_message := 'No active allocation found for this student.';
        ROLLBACK;
    WHEN OTHERS THEN
        p_result := 'ERROR';
        p_message := 'Error: ' || SQLERRM;
        ROLLBACK;
END proc_deallocate_room;
/
-- ============================================
-- PROCEDURE: Register Complaint
-- Creates a new complaint with auto-generated number
-- ============================================
CREATE OR REPLACE PROCEDURE proc_register_complaint (
    p_student_id    IN NUMBER,
    p_category_id   IN NUMBER,
    p_subject       IN VARCHAR2,
    p_description   IN CLOB,
    p_priority      IN VARCHAR2 DEFAULT 'MEDIUM',
    p_complaint_id  OUT NUMBER,
    p_complaint_num OUT VARCHAR2,
    p_result        OUT VARCHAR2,
    p_message       OUT VARCHAR2
)
IS
    v_room_id       NUMBER;
    v_student_exists NUMBER;
BEGIN
    -- Validate student
    SELECT COUNT(*), MAX(room_id)
    INTO v_student_exists, v_room_id
    FROM students
    WHERE student_id = p_student_id;
    
    IF v_student_exists = 0 THEN
        p_result := 'ERROR';
        p_message := 'Student not found.';
        RETURN;
    END IF;
    
    -- Generate complaint ID and number
    p_complaint_id := seq_complaints.NEXTVAL;
    p_complaint_num := 'CMP-' || TO_CHAR(SYSDATE, 'YYYYMM') || '-' || LPAD(seq_complaint_number.NEXTVAL, 5, '0');
    
    -- Insert complaint
    INSERT INTO complaints (
        complaint_id, complaint_number, student_id, category_id,
        subject, description, priority, status, room_id, created_at
    ) VALUES (
        p_complaint_id, p_complaint_num, p_student_id, p_category_id,
        p_subject, p_description, p_priority, 'PENDING', v_room_id, CURRENT_TIMESTAMP
    );
    
    -- Create notification for student
    INSERT INTO notifications (
        notification_id, user_id, title, message, notification_type, 
        reference_type, reference_id, created_at
    )
    SELECT seq_notifications.NEXTVAL, s.user_id, 
           'Complaint Registered', 
           'Your complaint ' || p_complaint_num || ' has been registered successfully.',
           'SUCCESS', 'COMPLAINT', p_complaint_id, CURRENT_TIMESTAMP
    FROM students s WHERE s.student_id = p_student_id;
    
    COMMIT;
    
    p_result := 'SUCCESS';
    p_message := 'Complaint registered successfully.';
    
EXCEPTION
    WHEN OTHERS THEN
        p_result := 'ERROR';
        p_message := 'Error: ' || SQLERRM;
        ROLLBACK;
END proc_register_complaint;
/
-- ============================================
-- PROCEDURE: Update Complaint Status
-- Updates complaint status with logging
-- ============================================
CREATE OR REPLACE PROCEDURE proc_update_complaint_status (
    p_complaint_id      IN NUMBER,
    p_new_status        IN VARCHAR2,
    p_assigned_to       IN NUMBER DEFAULT NULL,
    p_resolution_notes  IN CLOB DEFAULT NULL,
    p_updated_by        IN NUMBER,
    p_result            OUT VARCHAR2,
    p_message           OUT VARCHAR2
)
IS
    v_old_status    VARCHAR2(30);
    v_student_id    NUMBER;
    v_user_id       NUMBER;
    v_complaint_num VARCHAR2(50);
BEGIN
    -- Get current complaint details
    SELECT status, student_id, complaint_number
    INTO v_old_status, v_student_id, v_complaint_num
    FROM complaints
    WHERE complaint_id = p_complaint_id;
    
    -- Update complaint
    UPDATE complaints
    SET status = p_new_status,
        assigned_to = NVL(p_assigned_to, assigned_to),
        resolution_notes = NVL(p_resolution_notes, resolution_notes),
        resolved_by = CASE WHEN p_new_status IN ('RESOLVED', 'CLOSED') THEN p_updated_by ELSE resolved_by END,
        resolved_at = CASE WHEN p_new_status IN ('RESOLVED', 'CLOSED') THEN CURRENT_TIMESTAMP ELSE resolved_at END,
        updated_at = CURRENT_TIMESTAMP
    WHERE complaint_id = p_complaint_id;
    
    -- Get student's user_id for notification
    SELECT user_id INTO v_user_id FROM students WHERE student_id = v_student_id;
    
    -- Create notification for student
    INSERT INTO notifications (
        notification_id, user_id, title, message, notification_type, 
        reference_type, reference_id, created_at
    ) VALUES (
        seq_notifications.NEXTVAL, v_user_id,
        'Complaint Status Updated',
        'Your complaint ' || v_complaint_num || ' status changed from ' || v_old_status || ' to ' || p_new_status,
        'INFO', 'COMPLAINT', p_complaint_id, CURRENT_TIMESTAMP
    );
    
    COMMIT;
    
    p_result := 'SUCCESS';
    p_message := 'Complaint status updated successfully.';
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_result := 'ERROR';
        p_message := 'Complaint not found.';
        ROLLBACK;
    WHEN OTHERS THEN
        p_result := 'ERROR';
        p_message := 'Error: ' || SQLERRM;
        ROLLBACK;
END proc_update_complaint_status;
/
-- ============================================
-- PROCEDURE: Calculate and Impose Fine
-- Calculates fine based on type and creates record
-- ============================================
CREATE OR REPLACE PROCEDURE proc_impose_fine (
    p_student_id    IN NUMBER,
    p_fine_type     IN VARCHAR2,
    p_amount        IN NUMBER,
    p_description   IN VARCHAR2,
    p_imposed_by    IN NUMBER,
    p_due_days      IN NUMBER DEFAULT 30,
    p_fine_id       OUT NUMBER,
    p_fine_num      OUT VARCHAR2,
    p_result        OUT VARCHAR2,
    p_message       OUT VARCHAR2
)
IS
    v_user_id NUMBER;
BEGIN
    -- Validate student
    SELECT user_id INTO v_user_id
    FROM students
    WHERE student_id = p_student_id;
    
    -- Generate fine ID and number
    p_fine_id := seq_fines.NEXTVAL;
    p_fine_num := 'FIN-' || TO_CHAR(SYSDATE, 'YYYYMM') || '-' || LPAD(seq_fine_number.NEXTVAL, 5, '0');
    
    -- Insert fine
    INSERT INTO fines (
        fine_id, fine_number, student_id, fine_type, amount,
        description, fine_date, due_date, status, imposed_by, created_at
    ) VALUES (
        p_fine_id, p_fine_num, p_student_id, p_fine_type, p_amount,
        p_description, SYSDATE, SYSDATE + p_due_days, 'PENDING', p_imposed_by, CURRENT_TIMESTAMP
    );
    
    -- Create notification
    INSERT INTO notifications (
        notification_id, user_id, title, message, notification_type,
        reference_type, reference_id, created_at
    ) VALUES (
        seq_notifications.NEXTVAL, v_user_id,
        'Fine Imposed',
        'A fine of Rs.' || p_amount || ' has been imposed. Fine No: ' || p_fine_num || '. Due date: ' || TO_CHAR(SYSDATE + p_due_days, 'DD-MON-YYYY'),
        'WARNING', 'FINE', p_fine_id, CURRENT_TIMESTAMP
    );
    
    COMMIT;
    
    p_result := 'SUCCESS';
    p_message := 'Fine imposed successfully.';
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_result := 'ERROR';
        p_message := 'Student not found.';
        ROLLBACK;
    WHEN OTHERS THEN
        p_result := 'ERROR';
        p_message := 'Error: ' || SQLERRM;
        ROLLBACK;
END proc_impose_fine;
/
-- ============================================
-- PROCEDURE: Process Fine Payment
-- Records payment against a fine
-- ============================================
CREATE OR REPLACE PROCEDURE proc_process_fine_payment (
    p_fine_id           IN NUMBER,
    p_payment_amount    IN NUMBER,
    p_payment_method    IN VARCHAR2,
    p_transaction_id    IN VARCHAR2 DEFAULT NULL,
    p_received_by       IN NUMBER,
    p_payment_id        OUT NUMBER,
    p_result            OUT VARCHAR2,
    p_message           OUT VARCHAR2
)
IS
    v_fine_amount       NUMBER;
    v_paid_amount       NUMBER;
    v_balance           NUMBER;
    v_new_status        VARCHAR2(20);
    v_receipt_number    VARCHAR2(50);
    v_student_id        NUMBER;
    v_user_id           NUMBER;
BEGIN
    -- Get fine details
    SELECT amount, paid_amount, student_id
    INTO v_fine_amount, v_paid_amount, v_student_id
    FROM fines
    WHERE fine_id = p_fine_id AND status NOT IN ('PAID', 'WAIVED');
    
    v_balance := v_fine_amount - v_paid_amount;
    
    -- Validate payment amount
    IF p_payment_amount <= 0 THEN
        p_result := 'ERROR';
        p_message := 'Payment amount must be greater than zero.';
        RETURN;
    END IF;
    
    IF p_payment_amount > v_balance THEN
        p_result := 'ERROR';
        p_message := 'Payment amount exceeds balance. Current balance: Rs.' || v_balance;
        RETURN;
    END IF;
    
    -- Generate receipt number and payment ID
    p_payment_id := seq_fine_payments.NEXTVAL;
    v_receipt_number := 'RCP-' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '-' || LPAD(p_payment_id, 6, '0');
    
    -- Insert payment record
    INSERT INTO fine_payments (
        payment_id, fine_id, payment_amount, payment_date,
        payment_method, transaction_id, receipt_number, received_by, created_at
    ) VALUES (
        p_payment_id, p_fine_id, p_payment_amount, CURRENT_TIMESTAMP,
        p_payment_method, p_transaction_id, v_receipt_number, p_received_by, CURRENT_TIMESTAMP
    );
    
    -- Update fine record
    v_new_status := CASE 
        WHEN v_paid_amount + p_payment_amount >= v_fine_amount THEN 'PAID'
        ELSE 'PARTIALLY_PAID'
    END;
    
    UPDATE fines
    SET paid_amount = paid_amount + p_payment_amount,
        status = v_new_status,
        updated_at = CURRENT_TIMESTAMP
    WHERE fine_id = p_fine_id;
    
    -- Get user_id for notification
    SELECT user_id INTO v_user_id FROM students WHERE student_id = v_student_id;
    
    -- Create notification
    INSERT INTO notifications (
        notification_id, user_id, title, message, notification_type,
        reference_type, reference_id, created_at
    ) VALUES (
        seq_notifications.NEXTVAL, v_user_id,
        'Payment Received',
        'Payment of Rs.' || p_payment_amount || ' received. Receipt: ' || v_receipt_number,
        'SUCCESS', 'FINE', p_fine_id, CURRENT_TIMESTAMP
    );
    
    COMMIT;
    
    p_result := 'SUCCESS';
    p_message := 'Payment processed. Receipt: ' || v_receipt_number;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_result := 'ERROR';
        p_message := 'Fine not found or already paid/waived.';
        ROLLBACK;
    WHEN OTHERS THEN
        p_result := 'ERROR';
        p_message := 'Error: ' || SQLERRM;
        ROLLBACK;
END proc_process_fine_payment;
/
-- ============================================
-- PROCEDURE: Process Leave Request
-- Approves or rejects a leave request
-- ============================================
CREATE OR REPLACE PROCEDURE proc_process_leave_request (
    p_leave_id          IN NUMBER,
    p_action            IN VARCHAR2,  -- 'APPROVE' or 'REJECT'
    p_processed_by      IN NUMBER,
    p_rejection_reason  IN VARCHAR2 DEFAULT NULL,
    p_result            OUT VARCHAR2,
    p_message           OUT VARCHAR2
)
IS
    v_student_id    NUMBER;
    v_user_id       NUMBER;
    v_leave_number  VARCHAR2(50);
    v_current_status VARCHAR2(20);
    v_new_status    VARCHAR2(20);
BEGIN
    -- Get leave request details
    SELECT student_id, leave_number, status
    INTO v_student_id, v_leave_number, v_current_status
    FROM leave_requests
    WHERE leave_id = p_leave_id;
    
    -- Validate current status
    IF v_current_status != 'PENDING' THEN
        p_result := 'ERROR';
        p_message := 'Leave request is not in pending status. Current status: ' || v_current_status;
        RETURN;
    END IF;
    
    -- Set new status based on action
    IF UPPER(p_action) = 'APPROVE' THEN
        v_new_status := 'APPROVED';
    ELSIF UPPER(p_action) = 'REJECT' THEN
        v_new_status := 'REJECTED';
        IF p_rejection_reason IS NULL THEN
            p_result := 'ERROR';
            p_message := 'Rejection reason is required.';
            RETURN;
        END IF;
    ELSE
        p_result := 'ERROR';
        p_message := 'Invalid action. Use APPROVE or REJECT.';
        RETURN;
    END IF;
    
    -- Update leave request
    UPDATE leave_requests
    SET status = v_new_status,
        approved_by = p_processed_by,
        approved_at = CURRENT_TIMESTAMP,
        rejection_reason = p_rejection_reason,
        updated_at = CURRENT_TIMESTAMP
    WHERE leave_id = p_leave_id;
    
    -- Get user_id for notification
    SELECT user_id INTO v_user_id FROM students WHERE student_id = v_student_id;
    
    -- Create notification
    INSERT INTO notifications (
        notification_id, user_id, title, message, notification_type,
        reference_type, reference_id, created_at
    ) VALUES (
        seq_notifications.NEXTVAL, v_user_id,
        'Leave Request ' || v_new_status,
        'Your leave request ' || v_leave_number || ' has been ' || LOWER(v_new_status) || 
            CASE WHEN v_new_status = 'REJECTED' THEN '. Reason: ' || p_rejection_reason ELSE '.' END,
        CASE WHEN v_new_status = 'APPROVED' THEN 'SUCCESS' ELSE 'ERROR' END,
        'LEAVE', p_leave_id, CURRENT_TIMESTAMP
    );
    
    COMMIT;
    
    p_result := 'SUCCESS';
    p_message := 'Leave request ' || LOWER(v_new_status) || ' successfully.';
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_result := 'ERROR';
        p_message := 'Leave request not found.';
        ROLLBACK;
    WHEN OTHERS THEN
        p_result := 'ERROR';
        p_message := 'Error: ' || SQLERRM;
        ROLLBACK;
END proc_process_leave_request;
/
-- ============================================
-- PROCEDURE: Book Housekeeping Service
-- Creates a new housekeeping request
-- ============================================
CREATE OR REPLACE PROCEDURE proc_book_housekeeping (
    p_student_id        IN NUMBER,
    p_service_type      IN VARCHAR2,
    p_description       IN VARCHAR2,
    p_preferred_date    IN DATE DEFAULT NULL,
    p_preferred_time    IN VARCHAR2 DEFAULT NULL,
    p_urgency           IN VARCHAR2 DEFAULT 'NORMAL',
    p_request_id        OUT NUMBER,
    p_request_num       OUT VARCHAR2,
    p_result            OUT VARCHAR2,
    p_message           OUT VARCHAR2
)
IS
    v_room_id       NUMBER;
    v_hostel_status VARCHAR2(20);
BEGIN
    -- Get student's room
    SELECT room_id, hostel_status
    INTO v_room_id, v_hostel_status
    FROM students
    WHERE student_id = p_student_id;
    
    IF v_room_id IS NULL OR v_hostel_status != 'ALLOCATED' THEN
        p_result := 'ERROR';
        p_message := 'Student does not have an allocated room.';
        RETURN;
    END IF;
    
    -- Generate request ID and number
    p_request_id := seq_housekeeping_requests.NEXTVAL;
    p_request_num := 'HK-' || TO_CHAR(SYSDATE, 'YYYYMM') || '-' || LPAD(seq_hk_request_number.NEXTVAL, 5, '0');
    
    -- Insert request
    INSERT INTO housekeeping_requests (
        request_id, request_number, student_id, room_id, service_type,
        description, preferred_date, preferred_time, urgency, status, created_at
    ) VALUES (
        p_request_id, p_request_num, p_student_id, v_room_id, p_service_type,
        p_description, NVL(p_preferred_date, SYSDATE + 1), p_preferred_time, p_urgency, 'PENDING', CURRENT_TIMESTAMP
    );
    
    COMMIT;
    
    p_result := 'SUCCESS';
    p_message := 'Housekeeping request submitted. Request No: ' || p_request_num;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_result := 'ERROR';
        p_message := 'Student not found.';
        ROLLBACK;
    WHEN OTHERS THEN
        p_result := 'ERROR';
        p_message := 'Error: ' || SQLERRM;
        ROLLBACK;
END proc_book_housekeeping;
/
-- ============================================
-- PROCEDURE: Save Compatibility Responses
-- Saves student's compatibility questionnaire responses
-- ============================================
CREATE OR REPLACE PROCEDURE proc_save_compatibility_responses (
    p_student_id    IN NUMBER,
    p_responses     IN SYS.ODCIVARCHAR2LIST,  -- Array of 'question_id:response_value'
    p_result        OUT VARCHAR2,
    p_message       OUT VARCHAR2
)
IS
    v_question_id   NUMBER;
    v_response      VARCHAR2(500);
    v_separator_pos NUMBER;
BEGIN
    -- Delete existing responses for the student
    DELETE FROM compatibility_responses WHERE student_id = p_student_id;
    
    -- Insert new responses
    FOR i IN 1..p_responses.COUNT LOOP
        v_separator_pos := INSTR(p_responses(i), ':');
        v_question_id := TO_NUMBER(SUBSTR(p_responses(i), 1, v_separator_pos - 1));
        v_response := SUBSTR(p_responses(i), v_separator_pos + 1);
        
        INSERT INTO compatibility_responses (
            response_id, student_id, question_id, response_value, created_at
        ) VALUES (
            seq_compatibility_responses.NEXTVAL, p_student_id, v_question_id, v_response, CURRENT_TIMESTAMP
        );
    END LOOP;
    
    -- Update student's compatibility_completed flag
    UPDATE students
    SET compatibility_completed = 'Y',
        updated_at = CURRENT_TIMESTAMP
    WHERE student_id = p_student_id;
    
    COMMIT;
    
    p_result := 'SUCCESS';
    p_message := 'Compatibility responses saved successfully.';
    
EXCEPTION
    WHEN OTHERS THEN
        p_result := 'ERROR';
        p_message := 'Error: ' || SQLERRM;
        ROLLBACK;
END proc_save_compatibility_responses;
/
-- ============================================
-- PROCEDURE: Create Announcement
-- Creates a new system announcement
-- ============================================
CREATE OR REPLACE PROCEDURE proc_create_announcement (
    p_title             IN VARCHAR2,
    p_content           IN CLOB,
    p_announcement_type IN VARCHAR2,
    p_target_audience   IN VARCHAR2,
    p_target_block_id   IN NUMBER DEFAULT NULL,
    p_priority          IN VARCHAR2 DEFAULT 'NORMAL',
    p_start_date        IN DATE DEFAULT SYSDATE,
    p_end_date          IN DATE DEFAULT NULL,
    p_is_pinned         IN CHAR DEFAULT 'N',
    p_created_by        IN NUMBER,
    p_announcement_id   OUT NUMBER,
    p_result            OUT VARCHAR2,
    p_message           OUT VARCHAR2
)
IS
BEGIN
    p_announcement_id := seq_announcements.NEXTVAL;
    
    INSERT INTO announcements (
        announcement_id, title, content, announcement_type, target_audience,
        target_block_id, priority, start_date, end_date, is_pinned,
        is_active, created_by, created_at
    ) VALUES (
        p_announcement_id, p_title, p_content, p_announcement_type, p_target_audience,
        p_target_block_id, p_priority, p_start_date, p_end_date, p_is_pinned,
        'Y', p_created_by, CURRENT_TIMESTAMP
    );
    
    -- Create notifications for target audience
    IF p_target_audience = 'ALL' OR p_target_audience = 'STUDENTS' THEN
        INSERT INTO notifications (
            notification_id, user_id, title, message, notification_type,
            reference_type, reference_id, created_at
        )
        SELECT seq_notifications.NEXTVAL, s.user_id,
               'New Announcement: ' || p_title,
               SUBSTR(p_content, 1, 200) || CASE WHEN LENGTH(p_content) > 200 THEN '...' ELSE '' END,
               CASE p_priority WHEN 'CRITICAL' THEN 'WARNING' ELSE 'INFO' END,
               'ANNOUNCEMENT', p_announcement_id, CURRENT_TIMESTAMP
        FROM students s
        WHERE (p_target_block_id IS NULL OR s.room_id IN (SELECT room_id FROM rooms WHERE block_id = p_target_block_id));
    END IF;
    
    COMMIT;
    
    p_result := 'SUCCESS';
    p_message := 'Announcement created successfully.';
    
EXCEPTION
    WHEN OTHERS THEN
        p_result := 'ERROR';
        p_message := 'Error: ' || SQLERRM;
        ROLLBACK;
END proc_create_announcement;
/
