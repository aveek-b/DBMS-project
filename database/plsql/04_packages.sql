-- ============================================
-- HOSTEL MANAGEMENT SYSTEM - PACKAGES
-- Oracle PL/SQL Packages
-- ============================================
-- ============================================
-- PACKAGE: Room Management
-- Handles all room-related operations
-- ============================================
CREATE OR REPLACE PACKAGE pkg_room_management AS
    -- Types
    TYPE t_room_record IS RECORD (
        room_id         NUMBER,
        room_number     VARCHAR2(20),
        block_name      VARCHAR2(100),
        capacity        NUMBER,
        occupancy       NUMBER,
        available       NUMBER,
        status          VARCHAR2(20)
    );
    TYPE t_room_table IS TABLE OF t_room_record;
    
    -- Procedures
    PROCEDURE allocate_room(
        p_student_id    IN NUMBER,
        p_room_id       IN NUMBER,
        p_allocated_by  IN NUMBER,
        p_result        OUT VARCHAR2,
        p_message       OUT VARCHAR2
    );
    
    PROCEDURE deallocate_room(
        p_student_id    IN NUMBER,
        p_remarks       IN VARCHAR2,
        p_result        OUT VARCHAR2,
        p_message       OUT VARCHAR2
    );
    
    PROCEDURE transfer_room(
        p_student_id    IN NUMBER,
        p_new_room_id   IN NUMBER,
        p_transferred_by IN NUMBER,
        p_reason        IN VARCHAR2,
        p_result        OUT VARCHAR2,
        p_message       OUT VARCHAR2
    );
    
    -- Functions
    FUNCTION get_available_rooms(
        p_block_id      IN NUMBER DEFAULT NULL,
        p_gender        IN VARCHAR2 DEFAULT NULL
    ) RETURN SYS_REFCURSOR;
    
    FUNCTION get_occupancy_stats(
        p_block_id      IN NUMBER DEFAULT NULL
    ) RETURN SYS_REFCURSOR;
    
END pkg_room_management;
/
CREATE OR REPLACE PACKAGE BODY pkg_room_management AS
    PROCEDURE allocate_room(
        p_student_id    IN NUMBER,
        p_room_id       IN NUMBER,
        p_allocated_by  IN NUMBER,
        p_result        OUT VARCHAR2,
        p_message       OUT VARCHAR2
    ) IS
    BEGIN
        proc_allocate_room(
            p_student_id    => p_student_id,
            p_room_id       => p_room_id,
            p_allocated_by  => p_allocated_by,
            p_remarks       => NULL,
            p_result        => p_result,
            p_message       => p_message
        );
    END allocate_room;
    
    PROCEDURE deallocate_room(
        p_student_id    IN NUMBER,
        p_remarks       IN VARCHAR2,
        p_result        OUT VARCHAR2,
        p_message       OUT VARCHAR2
    ) IS
    BEGIN
        proc_deallocate_room(
            p_student_id    => p_student_id,
            p_remarks       => p_remarks,
            p_result        => p_result,
            p_message       => p_message
        );
    END deallocate_room;
    
    PROCEDURE transfer_room(
        p_student_id    IN NUMBER,
        p_new_room_id   IN NUMBER,
        p_transferred_by IN NUMBER,
        p_reason        IN VARCHAR2,
        p_result        OUT VARCHAR2,
        p_message       OUT VARCHAR2
    ) IS
        v_old_room_id NUMBER;
    BEGIN
        -- Get current room
        SELECT room_id INTO v_old_room_id
        FROM students WHERE student_id = p_student_id;
        
        IF v_old_room_id IS NULL THEN
            p_result := 'ERROR';
            p_message := 'Student does not have a current room.';
            RETURN;
        END IF;
        
        -- Deallocate current room
        proc_deallocate_room(p_student_id, 'Transfer to new room', p_result, p_message);
        
        IF p_result = 'ERROR' THEN
            RETURN;
        END IF;
        
        -- Allocate new room
        proc_allocate_room(p_student_id, p_new_room_id, p_transferred_by, 
                          'Transfer from room. Reason: ' || p_reason, p_result, p_message);
        
        -- Update allocation type
        IF p_result = 'SUCCESS' THEN
            UPDATE room_allocations
            SET allocation_type = 'TRANSFER'
            WHERE student_id = p_student_id 
            AND room_id = p_new_room_id
            AND status = 'ACTIVE';
            COMMIT;
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            p_result := 'ERROR';
            p_message := 'Error: ' || SQLERRM;
            ROLLBACK;
    END transfer_room;
    
    FUNCTION get_available_rooms(
        p_block_id      IN NUMBER DEFAULT NULL,
        p_gender        IN VARCHAR2 DEFAULT NULL
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT r.room_id, r.room_number, hb.block_name,
                   r.room_type, r.capacity, r.current_occupancy,
                   r.capacity - r.current_occupancy AS available_beds,
                   r.rent_amount, r.ac_available, r.attached_bathroom, r.status
            FROM rooms r
            JOIN hostel_blocks hb ON r.block_id = hb.block_id
            WHERE r.status IN ('AVAILABLE', 'OCCUPIED')
            AND r.current_occupancy < r.capacity
            AND (p_block_id IS NULL OR r.block_id = p_block_id)
            AND (p_gender IS NULL OR hb.block_type = 'COED' OR hb.block_type = p_gender)
            ORDER BY hb.block_name, r.floor_number, r.room_number;
        
        RETURN v_cursor;
    END get_available_rooms;
    
    FUNCTION get_occupancy_stats(
        p_block_id      IN NUMBER DEFAULT NULL
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT * FROM vw_hostel_occupancy_stats
            WHERE p_block_id IS NULL OR block_id = p_block_id;
        
        RETURN v_cursor;
    END get_occupancy_stats;
END pkg_room_management;
/
-- ============================================
-- PACKAGE: Complaint Management
-- Handles all complaint-related operations
-- ============================================
CREATE OR REPLACE PACKAGE pkg_complaint_management AS
    
    PROCEDURE register_complaint(
        p_student_id    IN NUMBER,
        p_category_id   IN NUMBER,
        p_subject       IN VARCHAR2,
        p_description   IN CLOB,
        p_priority      IN VARCHAR2,
        p_complaint_id  OUT NUMBER,
        p_result        OUT VARCHAR2,
        p_message       OUT VARCHAR2
    );
    
    PROCEDURE update_status(
        p_complaint_id  IN NUMBER,
        p_new_status    IN VARCHAR2,
        p_assigned_to   IN NUMBER,
        p_notes         IN CLOB,
        p_updated_by    IN NUMBER,
        p_result        OUT VARCHAR2,
        p_message       OUT VARCHAR2
    );
    
    PROCEDURE add_feedback(
        p_complaint_id  IN NUMBER,
        p_rating        IN NUMBER,
        p_comments      IN VARCHAR2,
        p_result        OUT VARCHAR2,
        p_message       OUT VARCHAR2
    );
    
    FUNCTION get_student_complaints(
        p_student_id    IN NUMBER,
        p_status        IN VARCHAR2 DEFAULT NULL
    ) RETURN SYS_REFCURSOR;
    
    FUNCTION get_block_complaints(
        p_block_id      IN NUMBER,
        p_status        IN VARCHAR2 DEFAULT NULL
    ) RETURN SYS_REFCURSOR;
    
END pkg_complaint_management;
/
CREATE OR REPLACE PACKAGE BODY pkg_complaint_management AS
    PROCEDURE register_complaint(
        p_student_id    IN NUMBER,
        p_category_id   IN NUMBER,
        p_subject       IN VARCHAR2,
        p_description   IN CLOB,
        p_priority      IN VARCHAR2,
        p_complaint_id  OUT NUMBER,
        p_result        OUT VARCHAR2,
        p_message       OUT VARCHAR2
    ) IS
        v_complaint_num VARCHAR2(50);
    BEGIN
        proc_register_complaint(
            p_student_id    => p_student_id,
            p_category_id   => p_category_id,
            p_subject       => p_subject,
            p_description   => p_description,
            p_priority      => p_priority,
            p_complaint_id  => p_complaint_id,
            p_complaint_num => v_complaint_num,
            p_result        => p_result,
            p_message       => p_message
        );
    END register_complaint;
    
    PROCEDURE update_status(
        p_complaint_id  IN NUMBER,
        p_new_status    IN VARCHAR2,
        p_assigned_to   IN NUMBER,
        p_notes         IN CLOB,
        p_updated_by    IN NUMBER,
        p_result        OUT VARCHAR2,
        p_message       OUT VARCHAR2
    ) IS
    BEGIN
        proc_update_complaint_status(
            p_complaint_id      => p_complaint_id,
            p_new_status        => p_new_status,
            p_assigned_to       => p_assigned_to,
            p_resolution_notes  => p_notes,
            p_updated_by        => p_updated_by,
            p_result            => p_result,
            p_message           => p_message
        );
    END update_status;
    
    PROCEDURE add_feedback(
        p_complaint_id  IN NUMBER,
        p_rating        IN NUMBER,
        p_comments      IN VARCHAR2,
        p_result        OUT VARCHAR2,
        p_message       OUT VARCHAR2
    ) IS
    BEGIN
        UPDATE complaints
        SET feedback_rating = p_rating,
            feedback_comments = p_comments,
            updated_at = CURRENT_TIMESTAMP
        WHERE complaint_id = p_complaint_id
        AND status IN ('RESOLVED', 'CLOSED');
        
        IF SQL%ROWCOUNT = 0 THEN
            p_result := 'ERROR';
            p_message := 'Complaint not found or not resolved yet.';
        ELSE
            COMMIT;
            p_result := 'SUCCESS';
            p_message := 'Feedback submitted successfully.';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_result := 'ERROR';
            p_message := 'Error: ' || SQLERRM;
            ROLLBACK;
    END add_feedback;
    
    FUNCTION get_student_complaints(
        p_student_id    IN NUMBER,
        p_status        IN VARCHAR2 DEFAULT NULL
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT * FROM vw_complaint_summary
            WHERE roll_number = (SELECT roll_number FROM students WHERE student_id = p_student_id)
            AND (p_status IS NULL OR status = p_status)
            ORDER BY created_at DESC;
        
        RETURN v_cursor;
    END get_student_complaints;
    
    FUNCTION get_block_complaints(
        p_block_id      IN NUMBER,
        p_status        IN VARCHAR2 DEFAULT NULL
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT cs.* FROM vw_complaint_summary cs
            JOIN students s ON cs.roll_number = s.roll_number
            JOIN rooms r ON s.room_id = r.room_id
            WHERE r.block_id = p_block_id
            AND (p_status IS NULL OR cs.status = p_status)
            ORDER BY cs.created_at DESC;
        
        RETURN v_cursor;
    END get_block_complaints;
END pkg_complaint_management;
/
-- ============================================
-- PACKAGE: Compatibility System
-- Handles roommate compatibility calculations
-- ============================================
CREATE OR REPLACE PACKAGE pkg_compatibility AS
    
    FUNCTION calculate_score(
        p_student1_id   IN NUMBER,
        p_student2_id   IN NUMBER
    ) RETURN NUMBER;
    
    FUNCTION get_category(
        p_score         IN NUMBER
    ) RETURN VARCHAR2;
    
    FUNCTION get_compatibility_explanation(
        p_student1_id   IN NUMBER,
        p_student2_id   IN NUMBER
    ) RETURN CLOB;
    
    FUNCTION get_best_matches(
        p_student_id    IN NUMBER,
        p_limit         IN NUMBER DEFAULT 5
    ) RETURN SYS_REFCURSOR;
    
    PROCEDURE save_responses(
        p_student_id    IN NUMBER,
        p_responses     IN SYS.ODCIVARCHAR2LIST,
        p_result        OUT VARCHAR2,
        p_message       OUT VARCHAR2
    );
    
END pkg_compatibility;
/
CREATE OR REPLACE PACKAGE BODY pkg_compatibility AS
    FUNCTION calculate_score(
        p_student1_id   IN NUMBER,
        p_student2_id   IN NUMBER
    ) RETURN NUMBER IS
    BEGIN
        RETURN func_calculate_compatibility(p_student1_id, p_student2_id);
    END calculate_score;
    
    FUNCTION get_category(
        p_score         IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN func_get_compatibility_category(p_score);
    END get_category;
    
    FUNCTION get_compatibility_explanation(
        p_student1_id   IN NUMBER,
        p_student2_id   IN NUMBER
    ) RETURN CLOB IS
        v_explanation CLOB := '';
        v_r1 VARCHAR2(500);
        v_r2 VARCHAR2(500);
        v_match_status VARCHAR2(100);
        
        CURSOR c_questions IS
            SELECT question_id, category, question_text, weight_percentage
            FROM compatibility_questions
            WHERE is_active = 'Y'
            ORDER BY weight_percentage DESC;
    BEGIN
        v_explanation := 'Compatibility Analysis:' || CHR(10) || CHR(10);
        
        FOR q IN c_questions LOOP
            BEGIN
                SELECT response_value INTO v_r1
                FROM compatibility_responses
                WHERE student_id = p_student1_id AND question_id = q.question_id;
                
                SELECT response_value INTO v_r2
                FROM compatibility_responses
                WHERE student_id = p_student2_id AND question_id = q.question_id;
                
                IF v_r1 = v_r2 THEN
                    v_match_status := '✓ Match';
                ELSE
                    v_match_status := '✗ Different';
                END IF;
                
                v_explanation := v_explanation || q.category || ' (' || q.weight_percentage || '%): ' || 
                                v_match_status || CHR(10);
                
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_explanation := v_explanation || q.category || ': Not answered' || CHR(10);
            END;
        END LOOP;
        
        RETURN v_explanation;
    END get_compatibility_explanation;
    
    FUNCTION get_best_matches(
        p_student_id    IN NUMBER,
        p_limit         IN NUMBER DEFAULT 5
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
        v_gender VARCHAR2(10);
    BEGIN
        SELECT gender INTO v_gender
        FROM students WHERE student_id = p_student_id;
        
        OPEN v_cursor FOR
            SELECT s.student_id, s.roll_number, 
                   u.first_name || ' ' || NVL(u.last_name, '') AS full_name,
                   s.course, s.branch, s.year_of_study,
                   func_calculate_compatibility(p_student_id, s.student_id) AS compatibility_score,
                   func_get_compatibility_category(func_calculate_compatibility(p_student_id, s.student_id)) AS match_category
            FROM students s
            JOIN users u ON s.user_id = u.user_id
            WHERE s.student_id != p_student_id
            AND s.compatibility_completed = 'Y'
            AND s.gender = v_gender
            AND s.hostel_status = 'PENDING'
            AND func_calculate_compatibility(p_student_id, s.student_id) >= 0
            ORDER BY func_calculate_compatibility(p_student_id, s.student_id) DESC
            FETCH FIRST p_limit ROWS ONLY;
        
        RETURN v_cursor;
    END get_best_matches;
    
    PROCEDURE save_responses(
        p_student_id    IN NUMBER,
        p_responses     IN SYS.ODCIVARCHAR2LIST,
        p_result        OUT VARCHAR2,
        p_message       OUT VARCHAR2
    ) IS
    BEGIN
        proc_save_compatibility_responses(
            p_student_id    => p_student_id,
            p_responses     => p_responses,
            p_result        => p_result,
            p_message       => p_message
        );
    END save_responses;
END pkg_compatibility;
/
-- ============================================
-- PACKAGE: Reports and Analytics
-- Generates various reports
-- ============================================
CREATE OR REPLACE PACKAGE pkg_reports AS
    
    FUNCTION get_occupancy_report RETURN SYS_REFCURSOR;
    FUNCTION get_complaint_report(p_days IN NUMBER DEFAULT 30) RETURN SYS_REFCURSOR;
    FUNCTION get_fine_report(p_days IN NUMBER DEFAULT 30) RETURN SYS_REFCURSOR;
    FUNCTION get_leave_report(p_days IN NUMBER DEFAULT 30) RETURN SYS_REFCURSOR;
    FUNCTION get_monthly_summary RETURN SYS_REFCURSOR;
    
END pkg_reports;
/
CREATE OR REPLACE PACKAGE BODY pkg_reports AS
    FUNCTION get_occupancy_report RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT * FROM vw_hostel_occupancy_stats ORDER BY block_name;
        RETURN v_cursor;
    END get_occupancy_report;
    
    FUNCTION get_complaint_report(p_days IN NUMBER DEFAULT 30) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT cc.category_name,
                   COUNT(*) AS total_complaints,
                   SUM(CASE WHEN c.status = 'RESOLVED' THEN 1 ELSE 0 END) AS resolved,
                   SUM(CASE WHEN c.status = 'PENDING' THEN 1 ELSE 0 END) AS pending,
                   ROUND(AVG(CASE WHEN c.resolved_at IS NOT NULL 
                       THEN (CAST(c.resolved_at AS DATE) - CAST(c.created_at AS DATE)) * 24 
                       ELSE NULL END), 2) AS avg_resolution_hours
            FROM complaints c
            LEFT JOIN complaint_categories cc ON c.category_id = cc.category_id
            WHERE c.created_at >= SYSDATE - p_days
            GROUP BY cc.category_name
            ORDER BY total_complaints DESC;
        RETURN v_cursor;
    END get_complaint_report;
    
    FUNCTION get_fine_report(p_days IN NUMBER DEFAULT 30) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT fine_type,
                   COUNT(*) AS total_fines,
                   SUM(amount) AS total_amount,
                   SUM(paid_amount) AS collected_amount,
                   SUM(amount - paid_amount) AS pending_amount,
                   SUM(CASE WHEN status = 'PAID' THEN 1 ELSE 0 END) AS paid_count,
                   SUM(CASE WHEN status = 'OVERDUE' THEN 1 ELSE 0 END) AS overdue_count
            FROM fines
            WHERE fine_date >= SYSDATE - p_days
            GROUP BY fine_type
            ORDER BY total_amount DESC;
        RETURN v_cursor;
    END get_fine_report;
    
    FUNCTION get_leave_report(p_days IN NUMBER DEFAULT 30) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT leave_type,
                   COUNT(*) AS total_requests,
                   SUM(CASE WHEN status = 'APPROVED' THEN 1 ELSE 0 END) AS approved,
                   SUM(CASE WHEN status = 'REJECTED' THEN 1 ELSE 0 END) AS rejected,
                   SUM(CASE WHEN status = 'PENDING' THEN 1 ELSE 0 END) AS pending,
                   ROUND(SUM(CASE WHEN status = 'APPROVED' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS approval_rate,
                   SUM(CASE WHEN late_return = 'Y' THEN 1 ELSE 0 END) AS late_returns
            FROM leave_requests
            WHERE created_at >= SYSDATE - p_days
            GROUP BY leave_type
            ORDER BY total_requests DESC;
        RETURN v_cursor;
    END get_leave_report;
    
    FUNCTION get_monthly_summary RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT * FROM vw_monthly_analytics;
        RETURN v_cursor;
    END get_monthly_summary;
END pkg_reports;
/
