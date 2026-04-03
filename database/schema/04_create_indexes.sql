-- HOSTEL MANAGEMENT SYSTEM - INDEXES
-- Performance optimization indexes
-- ============================================
-- Indexes for USERS table
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_role ON users(role);
-- Indexes for STUDENTS table
CREATE INDEX idx_students_roll ON students(roll_number);
CREATE INDEX idx_students_room ON students(room_id);
CREATE INDEX idx_students_status ON students(hostel_status);
CREATE INDEX idx_students_branch ON students(branch);
CREATE INDEX idx_students_year ON students(year_of_study);
-- Indexes for ROOMS table
CREATE INDEX idx_rooms_block ON rooms(block_id);
CREATE INDEX idx_rooms_status ON rooms(status);
CREATE INDEX idx_rooms_floor ON rooms(floor_number);
-- Indexes for COMPLAINTS table
CREATE INDEX idx_complaints_student ON complaints(student_id);
CREATE INDEX idx_complaints_status ON complaints(status);
CREATE INDEX idx_complaints_priority ON complaints(priority);
CREATE INDEX idx_complaints_created ON complaints(created_at);
-- Indexes for FINES table
CREATE INDEX idx_fines_student ON fines(student_id);
CREATE INDEX idx_fines_status ON fines(status);
CREATE INDEX idx_fines_due_date ON fines(due_date);
-- Indexes for LEAVE_REQUESTS table
CREATE INDEX idx_leave_student ON leave_requests(student_id);
CREATE INDEX idx_leave_status ON leave_requests(status);
CREATE INDEX idx_leave_dates ON leave_requests(from_date, to_date);
-- Indexes for HOUSEKEEPING_REQUESTS table
CREATE INDEX idx_hk_student ON housekeeping_requests(student_id);
CREATE INDEX idx_hk_room ON housekeeping_requests(room_id);
CREATE INDEX idx_hk_status ON housekeeping_requests(status);
-- Indexes for NOTIFICATIONS table
CREATE INDEX idx_notif_user ON notifications(user_id);
CREATE INDEX idx_notif_read ON notifications(is_read);
-- Indexes for ROOM_ALLOCATIONS table
CREATE INDEX idx_alloc_student ON room_allocations(student_id);
CREATE INDEX idx_alloc_room ON room_allocations(room_id);
CREATE INDEX idx_alloc_status ON room_allocations(status);
-- Indexes for COMPATIBILITY_RESPONSES table
CREATE INDEX idx_compat_student ON compatibility_responses(student_id);
-- Indexes for AUDIT_LOG table
CREATE INDEX idx_audit_user ON audit_log(user_id);
CREATE INDEX idx_audit_action ON audit_log(action_type);
CREATE INDEX idx_audit_timestamp ON audit_log(action_timestamp);
