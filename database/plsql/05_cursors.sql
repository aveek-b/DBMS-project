-- ============================================
-- HOSTEL MANAGEMENT SYSTEM - CURSORS
-- Oracle PL/SQL Cursor Examples in Procedures
-- ============================================
-- ============================================
-- PROCEDURE: Generate Monthly Occupancy Report
-- Uses cursor to iterate through blocks
-- ============================================
CREATE OR REPLACE PROCEDURE proc_monthly_occupancy_report (
    p_month         IN NUMBER DEFAULT EXTRACT(MONTH FROM SYSDATE),
    p_year          IN NUMBER DEFAULT EXTRACT(YEAR FROM SYSDATE),
    p_report        OUT CLOB
)
IS
    CURSOR c_blocks IS
        SELECT block_id, block_name, block_type
        FROM hostel_blocks
        WHERE status = 'ACTIVE'
        ORDER BY block_name;
    
    CURSOR c_rooms(cp_block_id NUMBER) IS
        SELECT room_id, room_number, capacity, current_occupancy
        FROM rooms
        WHERE block_id = cp_block_id
        ORDER BY floor_number, room_number;
    
    v_total_capacity    NUMBER := 0;
    v_total_occupied    NUMBER := 0;
    v_block_capacity    NUMBER;
    v_block_occupied    NUMBER;
    v_report            CLOB := '';
BEGIN
    v_report := 'HOSTEL OCCUPANCY REPORT' || CHR(10);
    v_report := v_report || 'Month: ' || TO_CHAR(TO_DATE(p_month || '-' || p_year, 'MM-YYYY'), 'Month YYYY') || CHR(10);
    v_report := v_report || 'Generated: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || CHR(10);
    v_report := v_report || RPAD('=', 60, '=') || CHR(10) || CHR(10);
    
    FOR blk IN c_blocks LOOP
        v_block_capacity := 0;
        v_block_occupied := 0;
        
        v_report := v_report || 'Block: ' || blk.block_name || ' (' || blk.block_type || ')' || CHR(10);
        v_report := v_report || RPAD('-', 40, '-') || CHR(10);
        
        FOR rm IN c_rooms(blk.block_id) LOOP
            v_report := v_report || '  Room ' || rm.room_number || ': ' || 
                       rm.current_occupancy || '/' || rm.capacity || ' occupied' || CHR(10);
            v_block_capacity := v_block_capacity + rm.capacity;
            v_block_occupied := v_block_occupied + rm.current_occupancy;
        END LOOP;
        
        v_report := v_report || '  Block Total: ' || v_block_occupied || '/' || v_block_capacity || 
                   ' (' || ROUND(v_block_occupied * 100 / NULLIF(v_block_capacity, 0), 1) || '%)' || CHR(10) || CHR(10);
        
        v_total_capacity := v_total_capacity + v_block_capacity;
        v_total_occupied := v_total_occupied + v_block_occupied;
    END LOOP;
    
    v_report := v_report || RPAD('=', 60, '=') || CHR(10);
    v_report := v_report || 'OVERALL TOTAL: ' || v_total_occupied || '/' || v_total_capacity || 
               ' (' || ROUND(v_total_occupied * 100 / NULLIF(v_total_capacity, 0), 1) || '%)' || CHR(10);
    
    p_report := v_report;
END proc_monthly_occupancy_report;
/
-- ============================================
-- PROCEDURE: List Rooms with Vacant Seats
-- Uses cursor to find available accommodations
-- ============================================
CREATE OR REPLACE PROCEDURE proc_vacant_rooms_report (
    p_block_id      IN NUMBER DEFAULT NULL,
    p_min_beds      IN NUMBER DEFAULT 1,
    p_result        OUT SYS_REFCURSOR
)
IS
BEGIN
    OPEN p_result FOR
        SELECT r.room_id,
               r.room_number,
               hb.block_name,
               r.floor_number,
               r.room_type,
               r.capacity,
               r.current_occupancy,
               r.capacity - r.current_occupancy AS vacant_beds,
               r.rent_amount,
               CASE r.ac_available WHEN 'Y' THEN 'Yes' ELSE 'No' END AS ac,
               CASE r.attached_bathroom WHEN 'Y' THEN 'Yes' ELSE 'No' END AS attached_bath
        FROM rooms r
        JOIN hostel_blocks hb ON r.block_id = hb.block_id
        WHERE r.status IN ('AVAILABLE', 'OCCUPIED')
        AND r.capacity - r.current_occupancy >= p_min_beds
        AND (p_block_id IS NULL OR r.block_id = p_block_id)
        ORDER BY hb.block_name, r.floor_number, r.room_number;
END proc_vacant_rooms_report;
/
-- ============================================
-- PROCEDURE: Students with Pending Complaints
-- Uses cursor to identify students with issues
-- ============================================
CREATE OR REPLACE PROCEDURE proc_pending_complaints_report (
    p_block_id      IN NUMBER DEFAULT NULL,
    p_priority      IN VARCHAR2 DEFAULT NULL,
    p_result        OUT SYS_REFCURSOR
)
IS
BEGIN
    OPEN p_result FOR
        SELECT s.student_id,
               s.roll_number,
               u.first_name || ' ' || NVL(u.last_name, '') AS student_name,
               r.room_number,
               hb.block_name,
               COUNT(c.complaint_id) AS pending_count,
               MAX(c.priority) AS highest_priority,
               MIN(c.created_at) AS oldest_complaint,
               LISTAGG(c.complaint_number, ', ') WITHIN GROUP (ORDER BY c.created_at) AS complaint_numbers
        FROM students s
        JOIN users u ON s.user_id = u.user_id
        LEFT JOIN rooms r ON s.room_id = r.room_id
        LEFT JOIN hostel_blocks hb ON r.block_id = hb.block_id
        JOIN complaints c ON s.student_id = c.student_id
        WHERE c.status IN ('PENDING', 'IN_PROGRESS')
        AND (p_block_id IS NULL OR r.block_id = p_block_id)
        AND (p_priority IS NULL OR c.priority = p_priority)
        GROUP BY s.student_id, s.roll_number, u.first_name, u.last_name, 
                 r.room_number, hb.block_name
        ORDER BY pending_count DESC, oldest_complaint;
END proc_pending_complaints_report;
/
-- ============================================
-- PROCEDURE: Students with Pending Fines
-- Uses cursor for fine tracking
-- ============================================
CREATE OR REPLACE PROCEDURE proc_pending_fines_report (
    p_block_id          IN NUMBER DEFAULT NULL,
    p_min_amount        IN NUMBER DEFAULT 0,
    p_include_overdue   IN CHAR DEFAULT 'Y',
    p_result            OUT SYS_REFCURSOR
)
IS
BEGIN
    OPEN p_result FOR
        SELECT s.student_id,
               s.roll_number,
               u.first_name || ' ' || NVL(u.last_name, '') AS student_name,
               r.room_number,
               hb.block_name,
               u.phone_number,
               u.email,
               COUNT(f.fine_id) AS fine_count,
               SUM(f.amount) AS total_fines,
               SUM(f.paid_amount) AS total_paid,
               SUM(f.amount - f.paid_amount) AS balance_due,
               SUM(CASE WHEN f.status = 'OVERDUE' THEN f.amount - f.paid_amount ELSE 0 END) AS overdue_amount,
               MIN(f.due_date) AS earliest_due_date
        FROM students s
        JOIN users u ON s.user_id = u.user_id
        LEFT JOIN rooms r ON s.room_id = r.room_id
        LEFT JOIN hostel_blocks hb ON r.block_id = hb.block_id
        JOIN fines f ON s.student_id = f.student_id
        WHERE f.status IN ('PENDING', 'PARTIALLY_PAID', CASE WHEN p_include_overdue = 'Y' THEN 'OVERDUE' ELSE 'PENDING' END)
        AND (p_block_id IS NULL OR r.block_id = p_block_id)
        GROUP BY s.student_id, s.roll_number, u.first_name, u.last_name,
                 r.room_number, hb.block_name, u.phone_number, u.email
        HAVING SUM(f.amount - f.paid_amount) >= p_min_amount
        ORDER BY balance_due DESC;
END proc_pending_fines_report;
/
-- ============================================
-- PROCEDURE: Hostel Analytics Dashboard Data
-- Uses multiple cursors for dashboard
-- ============================================
CREATE OR REPLACE PROCEDURE proc_dashboard_analytics (
    p_block_id              IN NUMBER DEFAULT NULL,
    p_occupancy_stats       OUT SYS_REFCURSOR,
    p_complaint_stats       OUT SYS_REFCURSOR,
    p_fine_stats            OUT SYS_REFCURSOR,
    p_leave_stats           OUT SYS_REFCURSOR,
    p_recent_activities     OUT SYS_REFCURSOR
)
IS
BEGIN
    -- Occupancy statistics
    OPEN p_occupancy_stats FOR
        SELECT hb.block_name,
               NVL(SUM(r.capacity), 0) AS total_capacity,
               NVL(SUM(r.current_occupancy), 0) AS occupied,
               ROUND(NVL(SUM(r.current_occupancy), 0) * 100.0 / NULLIF(SUM(r.capacity), 0), 1) AS occupancy_pct
        FROM hostel_blocks hb
        LEFT JOIN rooms r ON hb.block_id = r.block_id
        WHERE hb.status = 'ACTIVE'
        AND (p_block_id IS NULL OR hb.block_id = p_block_id)
        GROUP BY hb.block_id, hb.block_name
        ORDER BY hb.block_name;
    
    -- Complaint statistics (last 30 days)
    OPEN p_complaint_stats FOR
        SELECT TO_CHAR(TRUNC(created_at), 'DD-Mon') AS date_label,
               COUNT(*) AS total,
               SUM(CASE WHEN status IN ('RESOLVED', 'CLOSED') THEN 1 ELSE 0 END) AS resolved
        FROM complaints c
        WHERE created_at >= SYSDATE - 30
        AND (p_block_id IS NULL OR c.room_id IN (SELECT room_id FROM rooms WHERE block_id = p_block_id))
        GROUP BY TRUNC(created_at)
        ORDER BY TRUNC(created_at);
    
    -- Fine collection statistics (last 30 days)
    OPEN p_fine_stats FOR
        SELECT TO_CHAR(TRUNC(fine_date), 'DD-Mon') AS date_label,
               SUM(amount) AS imposed,
               SUM(paid_amount) AS collected
        FROM fines f
        JOIN students s ON f.student_id = s.student_id
        WHERE fine_date >= SYSDATE - 30
        AND (p_block_id IS NULL OR s.room_id IN (SELECT room_id FROM rooms WHERE block_id = p_block_id))
        GROUP BY TRUNC(fine_date)
        ORDER BY TRUNC(fine_date);
    
    -- Leave request statistics (last 30 days)
    OPEN p_leave_stats FOR
        SELECT leave_type,
               COUNT(*) AS total,
               SUM(CASE WHEN status = 'APPROVED' THEN 1 ELSE 0 END) AS approved,
               SUM(CASE WHEN status = 'REJECTED' THEN 1 ELSE 0 END) AS rejected,
               SUM(CASE WHEN status = 'PENDING' THEN 1 ELSE 0 END) AS pending
        FROM leave_requests lr
        JOIN students s ON lr.student_id = s.student_id
        WHERE lr.created_at >= SYSDATE - 30
        AND (p_block_id IS NULL OR s.room_id IN (SELECT room_id FROM rooms WHERE block_id = p_block_id))
        GROUP BY leave_type
        ORDER BY total DESC;
    
    -- Recent activities (last 10)
    OPEN p_recent_activities FOR
        SELECT * FROM (
            SELECT 'COMPLAINT' AS activity_type,
                   c.complaint_number AS reference,
                   c.subject AS description,
                   c.created_at AS activity_time
            FROM complaints c
            JOIN students s ON c.student_id = s.student_id
            WHERE p_block_id IS NULL OR s.room_id IN (SELECT room_id FROM rooms WHERE block_id = p_block_id)
            UNION ALL
            SELECT 'LEAVE' AS activity_type,
                   lr.leave_number AS reference,
                   lr.leave_type || ' - ' || lr.reason AS description,
                   lr.created_at AS activity_time
            FROM leave_requests lr
            JOIN students s ON lr.student_id = s.student_id
            WHERE p_block_id IS NULL OR s.room_id IN (SELECT room_id FROM rooms WHERE block_id = p_block_id)
            UNION ALL
            SELECT 'FINE' AS activity_type,
                   f.fine_number AS reference,
                   f.fine_type || ' - Rs.' || f.amount AS description,
                   f.created_at AS activity_time
            FROM fines f
            JOIN students s ON f.student_id = s.student_id
            WHERE p_block_id IS NULL OR s.room_id IN (SELECT room_id FROM rooms WHERE block_id = p_block_id)
        )
        ORDER BY activity_time DESC
        FETCH FIRST 10 ROWS ONLY;
        
END proc_dashboard_analytics;
/
-- ============================================
-- PROCEDURE: Compatibility Score Distribution
-- ============================================
CREATE OR REPLACE PROCEDURE proc_compatibility_distribution (
    p_result        OUT SYS_REFCURSOR
)
IS
BEGIN
    OPEN p_result FOR
        WITH student_pairs AS (
            SELECT s1.student_id AS sid1, s2.student_id AS sid2,
                   func_calculate_compatibility(s1.student_id, s2.student_id) AS score
            FROM students s1
            CROSS JOIN students s2
            WHERE s1.student_id < s2.student_id
            AND s1.compatibility_completed = 'Y'
            AND s2.compatibility_completed = 'Y'
            AND s1.gender = s2.gender
        )
        SELECT 
            CASE 
                WHEN score >= 85 THEN 'Excellent (85-100)'
                WHEN score >= 70 THEN 'Good (70-84)'
                WHEN score >= 50 THEN 'Moderate (50-69)'
                ELSE 'Poor (0-49)'
            END AS category,
            COUNT(*) AS pair_count,
            ROUND(AVG(score), 2) AS avg_score
        FROM student_pairs
        WHERE score >= 0
        GROUP BY 
            CASE 
                WHEN score >= 85 THEN 'Excellent (85-100)'
                WHEN score >= 70 THEN 'Good (70-84)'
                WHEN score >= 50 THEN 'Moderate (50-69)'
                ELSE 'Poor (0-49)'
            END
        ORDER BY avg_score DESC;
END proc_compatibility_distribution;
/
