-- HOSTEL MANAGEMENT SYSTEM - VIEWS
-- Database views for dashboards and reports
-- ============================================
-- Drop existing views
BEGIN
    FOR v IN (SELECT view_name FROM user_views WHERE view_name LIKE 'V_%' OR view_name LIKE 'VW_%') LOOP
        EXECUTE IMMEDIATE 'DROP VIEW ' || v.view_name;
    END LOOP;
END;
/
-- ============================================
-- STUDENT DASHBOARD SUMMARY VIEW
-- ============================================
CREATE OR REPLACE VIEW vw_student_dashboard AS
SELECT 
    s.student_id,
    s.roll_number,
    u.first_name || ' ' || NVL(u.last_name, '') AS full_name,
    u.email,
    u.phone_number,
    s.course,
    s.branch,
    s.year_of_study,
    s.hostel_status,
    r.room_number,
    r.room_type,
    hb.block_name,
    r.floor_number,
    (SELECT COUNT(*) FROM complaints c WHERE c.student_id = s.student_id AND c.status IN ('PENDING', 'IN_PROGRESS')) AS pending_complaints,
    (SELECT NVL(SUM(amount - paid_amount), 0) FROM fines f WHERE f.student_id = s.student_id AND f.status IN ('PENDING', 'OVERDUE', 'PARTIALLY_PAID')) AS pending_fines,
    (SELECT COUNT(*) FROM leave_requests lr WHERE lr.student_id = s.student_id AND lr.status = 'PENDING') AS pending_leaves,
    (SELECT COUNT(*) FROM notifications n WHERE n.user_id = u.user_id AND n.is_read = 'N') AS unread_notifications
FROM students s
JOIN users u ON s.user_id = u.user_id
LEFT JOIN rooms r ON s.room_id = r.room_id
LEFT JOIN hostel_blocks hb ON r.block_id = hb.block_id;
-- ============================================
-- WARDEN DASHBOARD SUMMARY VIEW
-- ============================================
CREATE OR REPLACE VIEW vw_warden_dashboard AS
SELECT 
    w.warden_id,
    u.first_name || ' ' || NVL(u.last_name, '') AS warden_name,
    hb.block_id,
    hb.block_name,
    (SELECT COUNT(*) FROM students s JOIN rooms r ON s.room_id = r.room_id WHERE r.block_id = hb.block_id AND s.hostel_status = 'ALLOCATED') AS total_students,
    (SELECT COUNT(*) FROM rooms r WHERE r.block_id = hb.block_id) AS total_rooms,
    (SELECT NVL(SUM(r.capacity), 0) FROM rooms r WHERE r.block_id = hb.block_id) AS total_capacity,
    (SELECT NVL(SUM(r.current_occupancy), 0) FROM rooms r WHERE r.block_id = hb.block_id) AS current_occupancy,
    (SELECT COUNT(*) FROM complaints c JOIN students s ON c.student_id = s.student_id JOIN rooms r ON s.room_id = r.room_id WHERE r.block_id = hb.block_id AND c.status = 'PENDING') AS pending_complaints,
    (SELECT COUNT(*) FROM leave_requests lr JOIN students s ON lr.student_id = s.student_id JOIN rooms r ON s.room_id = r.room_id WHERE r.block_id = hb.block_id AND lr.status = 'PENDING') AS pending_leaves,
    (SELECT COUNT(*) FROM housekeeping_requests hr WHERE hr.room_id IN (SELECT room_id FROM rooms WHERE block_id = hb.block_id) AND hr.status = 'PENDING') AS pending_housekeeping
FROM wardens w
JOIN users u ON w.user_id = u.user_id
LEFT JOIN hostel_blocks hb ON w.assigned_block_id = hb.block_id;
-- ============================================
-- ROOM AVAILABILITY VIEW
-- ============================================
CREATE OR REPLACE VIEW vw_room_availability AS
SELECT 
    r.room_id,
    r.room_number,
    hb.block_name,
    r.floor_number,
    r.room_type,
    r.capacity,
    r.current_occupancy,
    r.capacity - r.current_occupancy AS available_beds,
    r.rent_amount,
    r.ac_available,
    r.attached_bathroom,
    r.amenities,
    r.status,
    CASE 
        WHEN r.current_occupancy = 0 THEN 'EMPTY'
        WHEN r.current_occupancy = r.capacity THEN 'FULL'
        ELSE 'PARTIAL'
    END AS occupancy_status,
    ROUND((r.current_occupancy / r.capacity) * 100, 2) AS occupancy_percentage
FROM rooms r
JOIN hostel_blocks hb ON r.block_id = hb.block_id
WHERE r.status != 'MAINTENANCE';
-- ============================================
-- OCCUPIED ROOMS VIEW
-- ============================================
CREATE OR REPLACE VIEW vw_occupied_rooms AS
SELECT 
    r.room_id,
    r.room_number,
    hb.block_name,
    r.floor_number,
    r.room_type,
    r.capacity,
    r.current_occupancy,
    LISTAGG(u.first_name || ' ' || NVL(u.last_name, '') || ' (' || s.roll_number || ')', ', ') WITHIN GROUP (ORDER BY s.roll_number) AS occupants
FROM rooms r
JOIN hostel_blocks hb ON r.block_id = hb.block_id
LEFT JOIN students s ON s.room_id = r.room_id AND s.hostel_status = 'ALLOCATED'
LEFT JOIN users u ON s.user_id = u.user_id
WHERE r.current_occupancy > 0
GROUP BY r.room_id, r.room_number, hb.block_name, r.floor_number, r.room_type, r.capacity, r.current_occupancy;
-- ============================================
-- COMPLAINT STATUS SUMMARY VIEW
-- ============================================
CREATE OR REPLACE VIEW vw_complaint_summary AS
SELECT 
    c.complaint_id,
    c.complaint_number,
    u.first_name || ' ' || NVL(u.last_name, '') AS student_name,
    s.roll_number,
    r.room_number,
    hb.block_name,
    cc.category_name,
    c.subject,
    c.priority,
    c.status,
    c.created_at,
    c.resolved_at,
    CASE 
        WHEN c.resolved_at IS NOT NULL THEN 
            ROUND((CAST(c.resolved_at AS DATE) - CAST(c.created_at AS DATE)) * 24, 2)
        ELSE NULL
    END AS resolution_hours,
    uw.first_name || ' ' || NVL(uw.last_name, '') AS assigned_to_name
FROM complaints c
JOIN students s ON c.student_id = s.student_id
JOIN users u ON s.user_id = u.user_id
LEFT JOIN rooms r ON s.room_id = r.room_id
LEFT JOIN hostel_blocks hb ON r.block_id = hb.block_id
LEFT JOIN complaint_categories cc ON c.category_id = cc.category_id
LEFT JOIN users uw ON c.assigned_to = uw.user_id;
-- ============================================
-- PENDING FINES SUMMARY VIEW
-- ============================================
CREATE OR REPLACE VIEW vw_pending_fines AS
SELECT 
    f.fine_id,
    f.fine_number,
    s.student_id,
    s.roll_number,
    u.first_name || ' ' || NVL(u.last_name, '') AS student_name,
    r.room_number,
    hb.block_name,
    f.fine_type,
    f.amount,
    f.paid_amount,
    f.amount - f.paid_amount AS balance_amount,
    f.fine_date,
    f.due_date,
    f.status,
    CASE 
        WHEN f.due_date < SYSDATE AND f.status NOT IN ('PAID', 'WAIVED') THEN 'OVERDUE'
        ELSE f.status
    END AS payment_status,
    CASE 
        WHEN f.due_date < SYSDATE THEN TRUNC(SYSDATE - f.due_date)
        ELSE 0
    END AS days_overdue
FROM fines f
JOIN students s ON f.student_id = s.student_id
JOIN users u ON s.user_id = u.user_id
LEFT JOIN rooms r ON s.room_id = r.room_id
LEFT JOIN hostel_blocks hb ON r.block_id = hb.block_id
WHERE f.status IN ('PENDING', 'OVERDUE', 'PARTIALLY_PAID');
-- ============================================
-- HOSTEL OCCUPANCY STATISTICS VIEW
-- ============================================
CREATE OR REPLACE VIEW vw_hostel_occupancy_stats AS
SELECT 
    hb.block_id,
    hb.block_name,
    hb.block_type,
    COUNT(r.room_id) AS total_rooms,
    NVL(SUM(r.capacity), 0) AS total_capacity,
    NVL(SUM(r.current_occupancy), 0) AS total_occupied,
    NVL(SUM(r.capacity), 0) - NVL(SUM(r.current_occupancy), 0) AS total_vacant,
    ROUND(NVL(SUM(r.current_occupancy), 0) / NULLIF(SUM(r.capacity), 0) * 100, 2) AS occupancy_percentage,
    COUNT(CASE WHEN r.status = 'AVAILABLE' THEN 1 END) AS available_rooms,
    COUNT(CASE WHEN r.status = 'FULL' THEN 1 END) AS full_rooms,
    COUNT(CASE WHEN r.status = 'MAINTENANCE' THEN 1 END) AS maintenance_rooms
FROM hostel_blocks hb
LEFT JOIN rooms r ON hb.block_id = r.block_id
WHERE hb.status = 'ACTIVE'
GROUP BY hb.block_id, hb.block_name, hb.block_type;
-- ============================================
-- STUDENT ROOMMATE VIEW
-- ============================================
CREATE OR REPLACE VIEW vw_student_roommates AS
SELECT 
    s.student_id,
    s.roll_number AS student_roll,
    u.first_name || ' ' || NVL(u.last_name, '') AS student_name,
    r.room_id,
    r.room_number,
    hb.block_name,
    sr.student_id AS roommate_id,
    sr.roll_number AS roommate_roll,
    ur.first_name || ' ' || NVL(ur.last_name, '') AS roommate_name,
    sr.course AS roommate_course,
    sr.branch AS roommate_branch,
    sr.year_of_study AS roommate_year,
    ur.phone_number AS roommate_phone,
    ur.email AS roommate_email
FROM students s
JOIN users u ON s.user_id = u.user_id
JOIN rooms r ON s.room_id = r.room_id
JOIN hostel_blocks hb ON r.block_id = hb.block_id
JOIN students sr ON sr.room_id = r.room_id AND sr.student_id != s.student_id
JOIN users ur ON sr.user_id = ur.user_id
WHERE s.hostel_status = 'ALLOCATED';
-- ============================================
-- LEAVE REQUESTS SUMMARY VIEW
-- ============================================
CREATE OR REPLACE VIEW vw_leave_requests_summary AS
SELECT 
    lr.leave_id,
    lr.leave_number,
    s.roll_number,
    u.first_name || ' ' || NVL(u.last_name, '') AS student_name,
    r.room_number,
    hb.block_name,
    lr.leave_type,
    lr.from_date,
    lr.to_date,
    lr.to_date - lr.from_date + 1 AS duration_days,
    lr.reason,
    lr.destination,
    lr.status,
    lr.created_at AS applied_on,
    ua.first_name || ' ' || NVL(ua.last_name, '') AS approved_by_name,
    lr.approved_at,
    lr.late_return
FROM leave_requests lr
JOIN students s ON lr.student_id = s.student_id
JOIN users u ON s.user_id = u.user_id
LEFT JOIN rooms r ON s.room_id = r.room_id
LEFT JOIN hostel_blocks hb ON r.block_id = hb.block_id
LEFT JOIN users ua ON lr.approved_by = ua.user_id;
-- ============================================
-- MONTHLY ANALYTICS VIEW
-- ============================================
CREATE OR REPLACE VIEW vw_monthly_analytics AS
SELECT 
    TO_CHAR(SYSDATE, 'YYYY-MM') AS month_year,
    (SELECT COUNT(*) FROM students WHERE hostel_status = 'ALLOCATED') AS total_students,
    (SELECT COUNT(*) FROM complaints WHERE TRUNC(created_at, 'MM') = TRUNC(SYSDATE, 'MM')) AS complaints_this_month,
    (SELECT COUNT(*) FROM complaints WHERE TRUNC(resolved_at, 'MM') = TRUNC(SYSDATE, 'MM')) AS complaints_resolved_this_month,
    (SELECT NVL(SUM(amount), 0) FROM fines WHERE TRUNC(fine_date, 'MM') = TRUNC(SYSDATE, 'MM')) AS fines_imposed_this_month,
    (SELECT NVL(SUM(payment_amount), 0) FROM fine_payments WHERE TRUNC(payment_date, 'MM') = TRUNC(SYSDATE, 'MM')) AS fines_collected_this_month,
    (SELECT COUNT(*) FROM leave_requests WHERE TRUNC(created_at, 'MM') = TRUNC(SYSDATE, 'MM')) AS leave_requests_this_month,
    (SELECT COUNT(*) FROM leave_requests WHERE TRUNC(approved_at, 'MM') = TRUNC(SYSDATE, 'MM') AND status = 'APPROVED') AS leaves_approved_this_month,
    (SELECT COUNT(*) FROM housekeeping_requests WHERE TRUNC(created_at, 'MM') = TRUNC(SYSDATE, 'MM')) AS housekeeping_requests_this_month,
    (SELECT COUNT(*) FROM visitor_log WHERE TRUNC(check_in_time, 'MM') = TRUNC(SYSDATE, 'MM')) AS visitors_this_month
FROM DUAL;
