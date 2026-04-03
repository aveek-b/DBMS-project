-- ============================================
-- HOSTEL MANAGEMENT SYSTEM - SAMPLE DATA
-- Insert test data for development
-- ============================================
-- Clear existing data (in reverse dependency order)
BEGIN
    DELETE FROM notifications;
    DELETE FROM audit_log;
    DELETE FROM compatibility_responses;
    DELETE FROM visitor_log;
    DELETE FROM housekeeping_requests;
    DELETE FROM leave_requests;
    DELETE FROM fine_payments;
    DELETE FROM fines;
    DELETE FROM complaints;
    DELETE FROM room_allocations;
    DELETE FROM students;
    DELETE FROM staff;
    DELETE FROM mess_menu;
    DELETE FROM rooms;
    DELETE FROM wardens;
    DELETE FROM users;
    DELETE FROM hostel_blocks;
    DELETE FROM complaint_categories;
    DELETE FROM compatibility_questions;
    DELETE FROM announcements;
    COMMIT;
END;
/
-- ============================================
-- INSERT HOSTEL BLOCKS
-- ============================================
INSERT INTO hostel_blocks (block_id, block_name, block_type, total_floors, address, contact_number, facilities, status)
VALUES (seq_hostel_blocks.NEXTVAL, 'Block A - Sunrise', 'MALE', 4, 'North Campus, Building A', '9876543210', 'Wi-Fi, Common Room, Gym, Parking', 'ACTIVE');
INSERT INTO hostel_blocks (block_id, block_name, block_type, total_floors, address, contact_number, facilities, status)
VALUES (seq_hostel_blocks.NEXTVAL, 'Block B - Moonlight', 'FEMALE', 4, 'North Campus, Building B', '9876543211', 'Wi-Fi, Common Room, Indoor Games, Parking', 'ACTIVE');
INSERT INTO hostel_blocks (block_id, block_name, block_type, total_floors, address, contact_number, facilities, status)
VALUES (seq_hostel_blocks.NEXTVAL, 'Block C - Galaxy', 'MALE', 5, 'South Campus, Building C', '9876543212', 'Wi-Fi, Study Hall, Gym, Cafeteria', 'ACTIVE');
INSERT INTO hostel_blocks (block_id, block_name, block_type, total_floors, address, contact_number, facilities, status)
VALUES (seq_hostel_blocks.NEXTVAL, 'Block D - Star', 'FEMALE', 5, 'South Campus, Building D', '9876543213', 'Wi-Fi, Study Hall, Indoor Games, Cafeteria', 'ACTIVE');
-- ============================================
-- INSERT USERS (Admin, Wardens, Students)
-- Password: 'password123' - In production, use proper hashing
-- ============================================
-- Admin user
INSERT INTO users (user_id, username, email, password_hash, role, first_name, last_name, phone_number, is_active)
VALUES (seq_users.NEXTVAL, 'admin', 'admin@hostel.edu', 'pbkdf2:sha256:260000$password123hash', 'ADMIN', 'System', 'Administrator', '9000000001', 'Y');
-- Warden users
INSERT INTO users (user_id, username, email, password_hash, role, first_name, last_name, phone_number, is_active)
VALUES (seq_users.NEXTVAL, 'warden_a', 'warden.a@hostel.edu', 'pbkdf2:sha256:260000$password123hash', 'WARDEN', 'Rajesh', 'Kumar', '9000000002', 'Y');
INSERT INTO users (user_id, username, email, password_hash, role, first_name, last_name, phone_number, is_active)
VALUES (seq_users.NEXTVAL, 'warden_b', 'warden.b@hostel.edu', 'pbkdf2:sha256:260000$password123hash', 'WARDEN', 'Sunita', 'Sharma', '9000000003', 'Y');
INSERT INTO users (user_id, username, email, password_hash, role, first_name, last_name, phone_number, is_active)
VALUES (seq_users.NEXTVAL, 'warden_c', 'warden.c@hostel.edu', 'pbkdf2:sha256:260000$password123hash', 'WARDEN', 'Amit', 'Verma', '9000000004', 'Y');
INSERT INTO users (user_id, username, email, password_hash, role, first_name, last_name, phone_number, is_active)
VALUES (seq_users.NEXTVAL, 'warden_d', 'warden.d@hostel.edu', 'pbkdf2:sha256:260000$password123hash', 'WARDEN', 'Priya', 'Singh', '9000000005', 'Y');
-- ============================================
-- INSERT WARDENS
-- ============================================
INSERT INTO wardens (warden_id, user_id, employee_id, department, designation, joining_date, qualification, experience_years, assigned_block_id, status)
SELECT seq_wardens.NEXTVAL, u.user_id, 'EMP-W001', 'Hostel Administration', 'Chief Warden', DATE '2018-06-15', 'M.A. in Social Work', 10, 1, 'ACTIVE'
FROM users u WHERE u.username = 'warden_a';
INSERT INTO wardens (warden_id, user_id, employee_id, department, designation, joining_date, qualification, experience_years, assigned_block_id, status)
SELECT seq_wardens.NEXTVAL, u.user_id, 'EMP-W002', 'Hostel Administration', 'Senior Warden', DATE '2019-08-01', 'M.Sc. in Psychology', 8, 2, 'ACTIVE'
FROM users u WHERE u.username = 'warden_b';
INSERT INTO wardens (warden_id, user_id, employee_id, department, designation, joining_date, qualification, experience_years, assigned_block_id, status)
SELECT seq_wardens.NEXTVAL, u.user_id, 'EMP-W003', 'Hostel Administration', 'Warden', DATE '2020-01-10', 'M.B.A.', 5, 3, 'ACTIVE'
FROM users u WHERE u.username = 'warden_c';
INSERT INTO wardens (warden_id, user_id, employee_id, department, designation, joining_date, qualification, experience_years, assigned_block_id, status)
SELECT seq_wardens.NEXTVAL, u.user_id, 'EMP-W004', 'Hostel Administration', 'Warden', DATE '2021-03-20', 'M.A. in English', 4, 4, 'ACTIVE'
FROM users u WHERE u.username = 'warden_d';
-- Update hostel_blocks with warden assignments
UPDATE hostel_blocks SET warden_id = (SELECT warden_id FROM wardens WHERE employee_id = 'EMP-W001') WHERE block_id = 1;
UPDATE hostel_blocks SET warden_id = (SELECT warden_id FROM wardens WHERE employee_id = 'EMP-W002') WHERE block_id = 2;
UPDATE hostel_blocks SET warden_id = (SELECT warden_id FROM wardens WHERE employee_id = 'EMP-W003') WHERE block_id = 3;
UPDATE hostel_blocks SET warden_id = (SELECT warden_id FROM wardens WHERE employee_id = 'EMP-W004') WHERE block_id = 4;
-- ============================================
-- INSERT ROOMS
-- ============================================
-- Block A rooms (Male)
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'A-101', 1, 1, 'DOUBLE', 2, 0, 5000, 'N', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'A-102', 1, 1, 'DOUBLE', 2, 0, 5000, 'N', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'A-103', 1, 1, 'TRIPLE', 3, 0, 4500, 'N', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'A-201', 1, 2, 'SINGLE', 1, 0, 8000, 'Y', 'Y', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'A-202', 1, 2, 'DOUBLE', 2, 0, 6000, 'Y', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'A-203', 1, 2, 'DOUBLE', 2, 0, 6000, 'Y', 'N', 'AVAILABLE');
-- Block B rooms (Female)
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'B-101', 2, 1, 'DOUBLE', 2, 0, 5000, 'N', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'B-102', 2, 1, 'DOUBLE', 2, 0, 5000, 'N', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'B-103', 2, 1, 'TRIPLE', 3, 0, 4500, 'N', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'B-201', 2, 2, 'SINGLE', 1, 0, 8000, 'Y', 'Y', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'B-202', 2, 2, 'DOUBLE', 2, 0, 6000, 'Y', 'N', 'AVAILABLE');
-- Block C rooms (Male)
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'C-101', 3, 1, 'QUAD', 4, 0, 4000, 'N', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'C-102', 3, 1, 'QUAD', 4, 0, 4000, 'N', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'C-201', 3, 2, 'DOUBLE', 2, 0, 5500, 'Y', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'C-202', 3, 2, 'DOUBLE', 2, 0, 5500, 'Y', 'N', 'AVAILABLE');
-- Block D rooms (Female)
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'D-101', 4, 1, 'TRIPLE', 3, 0, 4500, 'N', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'D-102', 4, 1, 'TRIPLE', 3, 0, 4500, 'N', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'D-201', 4, 2, 'DOUBLE', 2, 0, 6000, 'Y', 'Y', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'D-202', 4, 2, 'DOUBLE', 2, 0, 6000, 'Y', 'Y', 'AVAILABLE');
-- ============================================
-- INSERT STUDENT USERS AND PROFILES
-- ============================================
-- Male students
INSERT INTO users (user_id, username, email, password_hash, role, first_name, last_name, phone_number, is_active)
VALUES (seq_users.NEXTVAL, 'student001', 'rahul.sharma@student.edu', 'pbkdf2:sha256:260000$password123hash', 'STUDENT', 'Rahul', 'Sharma', '9100000001', 'Y');
INSERT INTO users (user_id, username, email, password_hash, role, first_name, last_name, phone_number, is_active)
VALUES (seq_users.NEXTVAL, 'student002', 'vikram.patel@student.edu', 'pbkdf2:sha256:260000$password123hash', 'STUDENT', 'Vikram', 'Patel', '9100000002', 'Y');
INSERT INTO users (user_id, username, email, password_hash, role, first_name, last_name, phone_number, is_active)
VALUES (seq_users.NEXTVAL, 'student003', 'arjun.singh@student.edu', 'pbkdf2:sha256:260000$password123hash', 'STUDENT', 'Arjun', 'Singh', '9100000003', 'Y');
INSERT INTO users (user_id, username, email, password_hash, role, first_name, last_name, phone_number, is_active)
VALUES (seq_users.NEXTVAL, 'student004', 'karan.mehta@student.edu', 'pbkdf2:sha256:260000$password123hash', 'STUDENT', 'Karan', 'Mehta', '9100000004', 'Y');
INSERT INTO users (user_id, username, email, password_hash, role, first_name, last_name, phone_number, is_active)
VALUES (seq_users.NEXTVAL, 'student005', 'ravi.kumar@student.edu', 'pbkdf2:sha256:260000$password123hash', 'STUDENT', 'Ravi', 'Kumar', '9100000005', 'Y');
-- Female students
INSERT INTO users (user_id, username, email, password_hash, role, first_name, last_name, phone_number, is_active)
VALUES (seq_users.NEXTVAL, 'student006', 'priya.gupta@student.edu', 'pbkdf2:sha256:260000$password123hash', 'STUDENT', 'Priya', 'Gupta', '9100000006', 'Y');
INSERT INTO users (user_id, username, email, password_hash, role, first_name, last_name, phone_number, is_active)
VALUES (seq_users.NEXTVAL, 'student007', 'anjali.verma@student.edu', 'pbkdf2:sha256:260000$password123hash', 'STUDENT', 'Anjali', 'Verma', '9100000007', 'Y');
INSERT INTO users (user_id, username, email, password_hash, role, first_name, last_name, phone_number, is_active)
VALUES (seq_users.NEXTVAL, 'student008', 'sneha.reddy@student.edu', 'pbkdf2:sha256:260000$password123hash', 'STUDENT', 'Sneha', 'Reddy', '9100000008', 'Y');
INSERT INTO users (user_id, username, email, password_hash, role, first_name, last_name, phone_number, is_active)
VALUES (seq_users.NEXTVAL, 'student009', 'meera.joshi@student.edu', 'pbkdf2:sha256:260000$password123hash', 'STUDENT', 'Meera', 'Joshi', '9100000009', 'Y');
INSERT INTO users (user_id, username, email, password_hash, role, first_name, last_name, phone_number, is_active)
VALUES (seq_users.NEXTVAL, 'student010', 'kavya.nair@student.edu', 'pbkdf2:sha256:260000$password123hash', 'STUDENT', 'Kavya', 'Nair', '9100000010', 'Y');
-- Insert student profiles
INSERT INTO students (student_id, user_id, roll_number, registration_number, course, branch, year_of_study, semester, batch_year, date_of_birth, gender, blood_group, permanent_address, city, state, pincode, parent_name, parent_phone, hostel_status)
SELECT seq_students.NEXTVAL, user_id, 'CSE2021001', 'REG2021001', 'B.Tech', 'Computer Science', 3, 5, 2021, DATE '2003-05-15', 'MALE', 'O+', '123 Main Street', 'Mumbai', 'Maharashtra', '400001', 'Mr. Sharma', '9800000001', 'PENDING'
FROM users WHERE username = 'student001';
INSERT INTO students (student_id, user_id, roll_number, registration_number, course, branch, year_of_study, semester, batch_year, date_of_birth, gender, blood_group, permanent_address, city, state, pincode, parent_name, parent_phone, hostel_status)
SELECT seq_students.NEXTVAL, user_id, 'CSE2021002', 'REG2021002', 'B.Tech', 'Computer Science', 3, 5, 2021, DATE '2003-08-22', 'MALE', 'A+', '456 Park Avenue', 'Delhi', 'Delhi', '110001', 'Mr. Patel', '9800000002', 'PENDING'
FROM users WHERE username = 'student002';
INSERT INTO students (student_id, user_id, roll_number, registration_number, course, branch, year_of_study, semester, batch_year, date_of_birth, gender, blood_group, permanent_address, city, state, pincode, parent_name, parent_phone, hostel_status)
SELECT seq_students.NEXTVAL, user_id, 'ECE2021003', 'REG2021003', 'B.Tech', 'Electronics', 3, 5, 2021, DATE '2003-03-10', 'MALE', 'B+', '789 Lake Road', 'Bangalore', 'Karnataka', '560001', 'Mr. Singh', '9800000003', 'PENDING'
FROM users WHERE username = 'student003';
INSERT INTO students (student_id, user_id, roll_number, registration_number, course, branch, year_of_study, semester, batch_year, date_of_birth, gender, blood_group, permanent_address, city, state, pincode, parent_name, parent_phone, hostel_status)
SELECT seq_students.NEXTVAL, user_id, 'ME2022001', 'REG2022001', 'B.Tech', 'Mechanical', 2, 3, 2022, DATE '2004-01-25', 'MALE', 'AB+', '321 Hill View', 'Pune', 'Maharashtra', '411001', 'Mr. Mehta', '9800000004', 'PENDING'
FROM users WHERE username = 'student004';
INSERT INTO students (student_id, user_id, roll_number, registration_number, course, branch, year_of_study, semester, batch_year, date_of_birth, gender, blood_group, permanent_address, city, state, pincode, parent_name, parent_phone, hostel_status)
SELECT seq_students.NEXTVAL, user_id, 'CE2022002', 'REG2022002', 'B.Tech', 'Civil', 2, 3, 2022, DATE '2004-07-18', 'MALE', 'O-', '654 River Side', 'Chennai', 'Tamil Nadu', '600001', 'Mr. Kumar', '9800000005', 'PENDING'
FROM users WHERE username = 'student005';
INSERT INTO students (student_id, user_id, roll_number, registration_number, course, branch, year_of_study, semester, batch_year, date_of_birth, gender, blood_group, permanent_address, city, state, pincode, parent_name, parent_phone, hostel_status)
SELECT seq_students.NEXTVAL, user_id, 'CSE2021004', 'REG2021004', 'B.Tech', 'Computer Science', 3, 5, 2021, DATE '2003-11-30', 'FEMALE', 'A-', '987 Garden Lane', 'Hyderabad', 'Telangana', '500001', 'Mr. Gupta', '9800000006', 'PENDING'
FROM users WHERE username = 'student006';
INSERT INTO students (student_id, user_id, roll_number, registration_number, course, branch, year_of_study, semester, batch_year, date_of_birth, gender, blood_group, permanent_address, city, state, pincode, parent_name, parent_phone, hostel_status)
SELECT seq_students.NEXTVAL, user_id, 'ECE2021005', 'REG2021005', 'B.Tech', 'Electronics', 3, 5, 2021, DATE '2003-04-12', 'FEMALE', 'B-', '147 Rose Street', 'Kolkata', 'West Bengal', '700001', 'Mr. Verma', '9800000007', 'PENDING'
FROM users WHERE username = 'student007';
INSERT INTO students (student_id, user_id, roll_number, registration_number, course, branch, year_of_study, semester, batch_year, date_of_birth, gender, blood_group, permanent_address, city, state, pincode, parent_name, parent_phone, hostel_status)
SELECT seq_students.NEXTVAL, user_id, 'IT2022003', 'REG2022003', 'B.Tech', 'Information Technology', 2, 3, 2022, DATE '2004-09-05', 'FEMALE', 'O+', '258 Beach Road', 'Vizag', 'Andhra Pradesh', '530001', 'Mr. Reddy', '9800000008', 'PENDING'
FROM users WHERE username = 'student008';
INSERT INTO students (student_id, user_id, roll_number, registration_number, course, branch, year_of_study, semester, batch_year, date_of_birth, gender, blood_group, permanent_address, city, state, pincode, parent_name, parent_phone, hostel_status)
SELECT seq_students.NEXTVAL, user_id, 'CSE2023001', 'REG2023001', 'B.Tech', 'Computer Science', 1, 1, 2023, DATE '2005-02-28', 'FEMALE', 'A+', '369 Mountain View', 'Jaipur', 'Rajasthan', '302001', 'Mr. Joshi', '9800000009', 'PENDING'
FROM users WHERE username = 'student009';
INSERT INTO students (student_id, user_id, roll_number, registration_number, course, branch, year_of_study, semester, batch_year, date_of_birth, gender, blood_group, permanent_address, city, state, pincode, parent_name, parent_phone, hostel_status)
SELECT seq_students.NEXTVAL, user_id, 'ECE2023002', 'REG2023002', 'B.Tech', 'Electronics', 1, 1, 2023, DATE '2005-06-14', 'FEMALE', 'AB-', '741 Coconut Grove', 'Kochi', 'Kerala', '682001', 'Mr. Nair', '9800000010', 'PENDING'
FROM users WHERE username = 'student010';
-- ============================================
-- INSERT COMPLAINT CATEGORIES
-- ============================================
INSERT INTO complaint_categories (category_id, category_name, description, priority_level, resolution_sla_hours)
VALUES (seq_complaint_categories.NEXTVAL, 'Electrical', 'Electrical issues like fan, light, socket problems', 'HIGH', 24);
INSERT INTO complaint_categories (category_id, category_name, description, priority_level, resolution_sla_hours)
VALUES (seq_complaint_categories.NEXTVAL, 'Plumbing', 'Water leakage, tap issues, toilet problems', 'HIGH', 24);
INSERT INTO complaint_categories (category_id, category_name, description, priority_level, resolution_sla_hours)
VALUES (seq_complaint_categories.NEXTVAL, 'Furniture', 'Bed, table, chair, cupboard issues', 'MEDIUM', 48);
INSERT INTO complaint_categories (category_id, category_name, description, priority_level, resolution_sla_hours)
VALUES (seq_complaint_categories.NEXTVAL, 'Cleanliness', 'Room cleaning, washroom cleaning issues', 'MEDIUM', 24);
INSERT INTO complaint_categories (category_id, category_name, description, priority_level, resolution_sla_hours)
VALUES (seq_complaint_categories.NEXTVAL, 'Internet/Wi-Fi', 'Network connectivity issues', 'MEDIUM', 12);
INSERT INTO complaint_categories (category_id, category_name, description, priority_level, resolution_sla_hours)
VALUES (seq_complaint_categories.NEXTVAL, 'Security', 'Security related concerns', 'CRITICAL', 4);
INSERT INTO complaint_categories (category_id, category_name, description, priority_level, resolution_sla_hours)
VALUES (seq_complaint_categories.NEXTVAL, 'Mess/Food', 'Food quality and mess related issues', 'MEDIUM', 24);
INSERT INTO complaint_categories (category_id, category_name, description, priority_level, resolution_sla_hours)
VALUES (seq_complaint_categories.NEXTVAL, 'Other', 'Other miscellaneous complaints', 'LOW', 72);
-- ============================================
-- INSERT COMPATIBILITY QUESTIONS
-- ============================================
INSERT INTO compatibility_questions (question_id, category, question_text, question_type, options, weight_percentage, display_order)
VALUES (seq_compatibility_questions.NEXTVAL, 'SLEEP_SCHEDULE', 'What time do you usually go to sleep?', 'SINGLE', '9 PM|10 PM|11 PM|12 AM|1 AM|After 1 AM', 10, 1);
INSERT INTO compatibility_questions (question_id, category, question_text, question_type, options, weight_percentage, display_order)
VALUES (seq_compatibility_questions.NEXTVAL, 'WAKE_TIME', 'What time do you usually wake up?', 'SINGLE', '5 AM|6 AM|7 AM|8 AM|9 AM|After 9 AM', 10, 2);
INSERT INTO compatibility_questions (question_id, category, question_text, question_type, options, weight_percentage, display_order)
VALUES (seq_compatibility_questions.NEXTVAL, 'CLEANLINESS', 'How would you rate your cleanliness level?', 'SCALE', '1|2|3|4|5', 15, 3);
INSERT INTO compatibility_questions (question_id, category, question_text, question_type, options, weight_percentage, display_order)
VALUES (seq_compatibility_questions.NEXTVAL, 'STUDY_HABITS', 'When do you prefer to study?', 'SINGLE', 'Early Morning|Morning|Afternoon|Evening|Night|Late Night', 15, 4);
INSERT INTO compatibility_questions (question_id, category, question_text, question_type, options, weight_percentage, display_order)
VALUES (seq_compatibility_questions.NEXTVAL, 'NOISE_TOLERANCE', 'How tolerant are you of noise while studying?', 'SCALE', '1|2|3|4|5', 15, 5);
INSERT INTO compatibility_questions (question_id, category, question_text, question_type, options, weight_percentage, display_order)
VALUES (seq_compatibility_questions.NEXTVAL, 'MUSIC_PREFERENCE', 'Do you like to play music/videos in the room?', 'SINGLE', 'Never|Sometimes with headphones|Sometimes without headphones|Often|Always', 10, 6);
INSERT INTO compatibility_questions (question_id, category, question_text, question_type, options, weight_percentage, display_order)
VALUES (seq_compatibility_questions.NEXTVAL, 'SOCIAL_HABITS', 'How often do you like to have friends over?', 'SINGLE', 'Never|Rarely|Sometimes|Often|Very Often', 10, 7);
INSERT INTO compatibility_questions (question_id, category, question_text, question_type, options, weight_percentage, display_order)
VALUES (seq_compatibility_questions.NEXTVAL, 'TEMPERATURE', 'What is your preferred room temperature?', 'SINGLE', 'Very Cool (AC at 18-20)|Cool (AC at 21-23)|Moderate (AC at 24-26)|Warm (Fan only)|No preference', 3, 8);
INSERT INTO compatibility_questions (question_id, category, question_text, question_type, options, weight_percentage, display_order)
VALUES (seq_compatibility_questions.NEXTVAL, 'SHARING', 'Are you comfortable sharing items (food, stationery, etc.)?', 'SINGLE', 'Yes, everything|Most things|Some things|Only if asked|Prefer not to share', 1, 9);
INSERT INTO compatibility_questions (question_id, category, question_text, question_type, options, weight_percentage, display_order)
VALUES (seq_compatibility_questions.NEXTVAL, 'PERSONALITY', 'How would you describe yourself?', 'SINGLE', 'Very Introverted|Somewhat Introverted|Ambivert|Somewhat Extroverted|Very Extroverted', 5, 10);
INSERT INTO compatibility_questions (question_id, category, question_text, question_type, options, weight_percentage, display_order)
VALUES (seq_compatibility_questions.NEXTVAL, 'SMOKING', 'What is your stance on smoking?', 'SINGLE', 'I smoke|I dont smoke but dont mind|I prefer smoke-free environment', 3, 11);
INSERT INTO compatibility_questions (question_id, category, question_text, question_type, options, weight_percentage, display_order)
VALUES (seq_compatibility_questions.NEXTVAL, 'FOOD_HABITS', 'What are your food preferences?', 'SINGLE', 'Vegetarian|Non-Vegetarian|Eggetarian|Vegan|No preference', 3, 12);
-- ============================================
-- INSERT STAFF
-- ============================================
INSERT INTO staff (staff_id, employee_id, first_name, last_name, staff_type, phone_number, assigned_block_id, shift, joining_date, salary, status)
VALUES (seq_staff.NEXTVAL, 'STF-HK001', 'Ramesh', 'Das', 'HOUSEKEEPING', '9200000001', 1, 'MORNING', DATE '2020-01-15', 15000, 'ACTIVE');
INSERT INTO staff (staff_id, employee_id, first_name, last_name, staff_type, phone_number, assigned_block_id, shift, joining_date, salary, status)
VALUES (seq_staff.NEXTVAL, 'STF-HK002', 'Lakshmi', 'Devi', 'HOUSEKEEPING', '9200000002', 2, 'MORNING', DATE '2019-06-20', 15000, 'ACTIVE');
INSERT INTO staff (staff_id, employee_id, first_name, last_name, staff_type, phone_number, assigned_block_id, shift, joining_date, salary, status)
VALUES (seq_staff.NEXTVAL, 'STF-SC001', 'Suresh', 'Yadav', 'SECURITY', '9200000003', NULL, 'NIGHT', DATE '2018-03-10', 18000, 'ACTIVE');
INSERT INTO staff (staff_id, employee_id, first_name, last_name, staff_type, phone_number, assigned_block_id, shift, joining_date, salary, status)
VALUES (seq_staff.NEXTVAL, 'STF-MT001', 'Ganesh', 'Prasad', 'MAINTENANCE', '9200000004', NULL, 'ROTATING', DATE '2017-08-25', 20000, 'ACTIVE');
INSERT INTO staff (staff_id, employee_id, first_name, last_name, staff_type, phone_number, assigned_block_id, shift, joining_date, salary, status)
VALUES (seq_staff.NEXTVAL, 'STF-MS001', 'Vijay', 'Cook', 'MESS', '9200000005', NULL, 'MORNING', DATE '2019-11-01', 22000, 'ACTIVE');
-- ============================================
-- INSERT MESS MENU
-- ============================================
-- Monday
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'MONDAY', 'BREAKFAST', 'Idli, Sambar, Coconut Chutney, Tea/Coffee', '07:30', '09:30', NULL);
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'MONDAY', 'LUNCH', 'Rice, Dal Fry, Aloo Gobi, Roti, Salad, Curd', '12:30', '14:30', NULL);
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'MONDAY', 'SNACKS', 'Samosa, Tea', '16:30', '17:30', NULL);
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'MONDAY', 'DINNER', 'Rice, Rajma, Jeera Aloo, Roti, Salad', '19:30', '21:30', NULL);
-- Tuesday
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'TUESDAY', 'BREAKFAST', 'Poha, Jalebi, Milk/Tea', '07:30', '09:30', NULL);
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'TUESDAY', 'LUNCH', 'Rice, Sambar, Bhindi Fry, Roti, Pickle, Buttermilk', '12:30', '14:30', NULL);
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'TUESDAY', 'SNACKS', 'Bread Pakora, Tea', '16:30', '17:30', NULL);
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'TUESDAY', 'DINNER', 'Rice, Chole, Boondi Raita, Roti, Salad', '19:30', '21:30', NULL);
-- Wednesday
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'WEDNESDAY', 'BREAKFAST', 'Paratha, Curd, Pickle, Tea/Coffee', '07:30', '09:30', NULL);
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'WEDNESDAY', 'LUNCH', 'Rice, Dal Tadka, Palak Paneer, Roti, Salad', '12:30', '14:30', NULL);
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'WEDNESDAY', 'SNACKS', 'Vada Pav, Tea', '16:30', '17:30', NULL);
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'WEDNESDAY', 'DINNER', 'Rice, Kadhi, Aloo Jeera, Roti, Papad', '19:30', '21:30', NULL);
-- Thursday
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'THURSDAY', 'BREAKFAST', 'Upma, Coconut Chutney, Banana, Tea/Coffee', '07:30', '09:30', NULL);
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'THURSDAY', 'LUNCH', 'Rice, Sambhar, Mixed Veg, Roti, Curd Rice', '12:30', '14:30', NULL);
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'THURSDAY', 'SNACKS', 'Dhokla, Tea', '16:30', '17:30', NULL);
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'THURSDAY', 'DINNER', 'Biryani, Raita, Mirchi ka Salan, Salad', '19:30', '21:30', NULL);
-- Friday
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'FRIDAY', 'BREAKFAST', 'Chole Bhature, Lassi', '07:30', '09:30', NULL);
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'FRIDAY', 'LUNCH', 'Rice, Dal Makhani, Paneer Butter Masala, Roti', '12:30', '14:30', NULL);
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'FRIDAY', 'SNACKS', 'Pav Bhaji, Tea', '16:30', '17:30', NULL);
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'FRIDAY', 'DINNER', 'Rice, Kofta Curry, Roti, Salad, Ice Cream', '19:30', '21:30', NULL);
-- Saturday
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'SATURDAY', 'BREAKFAST', 'Dosa, Sambar, Chutney, Coffee', '07:30', '09:30', NULL);
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'SATURDAY', 'LUNCH', 'Rice, Rasam, Cabbage Poriyal, Roti, Papad', '12:30', '14:30', NULL);
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'SATURDAY', 'SNACKS', 'Sandwich, Juice', '16:30', '17:30', NULL);
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'SATURDAY', 'DINNER', 'Pulao, Shahi Paneer, Raita, Roti, Gulab Jamun', '19:30', '21:30', NULL);
-- Sunday
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'SUNDAY', 'BREAKFAST', 'Puri, Aloo Sabzi, Halwa, Tea/Coffee', '07:30', '09:30', NULL);
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'SUNDAY', 'LUNCH', 'Chicken/Paneer Biryani, Raita, Salad, Dessert', '12:30', '14:30', NULL);
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'SUNDAY', 'SNACKS', 'Spring Roll, Cold Drink', '16:30', '17:30', NULL);
INSERT INTO mess_menu (menu_id, day_of_week, meal_type, menu_items, timing_start, timing_end, block_id)
VALUES (seq_mess_menu.NEXTVAL, 'SUNDAY', 'DINNER', 'Roti, Dal Fry, Matar Paneer, Rice, Kheer', '19:30', '21:30', NULL);
-- ============================================
-- INSERT ANNOUNCEMENTS
-- ============================================
INSERT INTO announcements (announcement_id, title, content, announcement_type, target_audience, priority, start_date, end_date, is_pinned, created_by)
SELECT seq_announcements.NEXTVAL, 'Welcome to New Academic Session 2024-25', 
       'Dear Students, Welcome to the new academic session. All hostel rules and regulations must be followed strictly. Please report any issues to your respective wardens.',
       'GENERAL', 'ALL', 'HIGH', SYSDATE, SYSDATE + 30, 'Y', user_id
FROM users WHERE username = 'admin';
INSERT INTO announcements (announcement_id, title, content, announcement_type, target_audience, priority, start_date, end_date, is_pinned, created_by)
SELECT seq_announcements.NEXTVAL, 'Hostel Maintenance Schedule', 
       'Water tank cleaning will be conducted on Saturday, 10 AM to 2 PM. Please store drinking water beforehand.',
       'MAINTENANCE', 'STUDENTS', 'NORMAL', SYSDATE, SYSDATE + 7, 'N', user_id
FROM users WHERE username = 'admin';
INSERT INTO announcements (announcement_id, title, content, announcement_type, target_audience, priority, start_date, end_date, is_pinned, created_by)
SELECT seq_announcements.NEXTVAL, 'Mess Timing Update', 
       'From next week, dinner timing will be extended to 10:00 PM due to exam schedule.',
       'MESS', 'STUDENTS', 'NORMAL', SYSDATE, SYSDATE + 14, 'N', user_id
FROM users WHERE username = 'admin';
COMMIT;
-- Display summary
SELECT 'Users: ' || COUNT(*) AS summary FROM users
UNION ALL
SELECT 'Students: ' || COUNT(*) FROM students
UNION ALL
SELECT 'Wardens: ' || COUNT(*) FROM wardens
UNION ALL
SELECT 'Hostel Blocks: ' || COUNT(*) FROM hostel_blocks
UNION ALL
SELECT 'Rooms: ' || COUNT(*) FROM rooms
UNION ALL
SELECT 'Staff: ' || COUNT(*) FROM staff
UNION ALL
SELECT 'Mess Menu Items: ' || COUNT(*) FROM mess_menu
UNION ALL
SELECT 'Compatibility Questions: ' || COUNT(*) FROM compatibility_questions
UNION ALL
SELECT 'Complaint Categories: ' || COUNT(*) FROM complaint_categories
UNION ALL
SELECT 'Announcements: ' || COUNT(*) FROM announcements;
