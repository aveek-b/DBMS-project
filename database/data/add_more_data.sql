-- ============================================
-- ADDENDUM: More Rooms, Students & Compatibility Responses
-- Run AFTER sample_data.sql and update_student_cgpa.sql
-- ============================================

-- ============================================
-- ADDITIONAL ROOMS
-- ============================================

-- Block A (Male) - Floors 3 & 4
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'A-301', 1, 3, 'SINGLE', 1, 0, 9000, 'Y', 'Y', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'A-302', 1, 3, 'DOUBLE', 2, 0, 7000, 'Y', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'A-303', 1, 3, 'DOUBLE', 2, 0, 7000, 'Y', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'A-304', 1, 3, 'TRIPLE', 3, 0, 5500, 'Y', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'A-401', 1, 4, 'SINGLE', 1, 0, 9500, 'Y', 'Y', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'A-402', 1, 4, 'DOUBLE', 2, 0, 7500, 'Y', 'Y', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'A-403', 1, 4, 'DOUBLE', 2, 0, 7500, 'Y', 'Y', 'AVAILABLE');

-- Block B (Female) - Floors 3 & 4
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'B-301', 2, 3, 'SINGLE', 1, 0, 9000, 'Y', 'Y', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'B-302', 2, 3, 'DOUBLE', 2, 0, 7000, 'Y', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'B-303', 2, 3, 'DOUBLE', 2, 0, 7000, 'Y', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'B-304', 2, 3, 'TRIPLE', 3, 0, 5500, 'Y', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'B-401', 2, 4, 'SINGLE', 1, 0, 9500, 'Y', 'Y', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'B-402', 2, 4, 'DOUBLE', 2, 0, 7500, 'Y', 'Y', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'B-403', 2, 4, 'DOUBLE', 2, 0, 7500, 'Y', 'Y', 'AVAILABLE');

-- Block C (Male) - Floors 3, 4 & 5
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'C-301', 3, 3, 'TRIPLE', 3, 0, 5000, 'N', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'C-302', 3, 3, 'DOUBLE', 2, 0, 5500, 'N', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'C-303', 3, 3, 'QUAD', 4, 0, 4000, 'N', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'C-401', 3, 4, 'DOUBLE', 2, 0, 6500, 'Y', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'C-402', 3, 4, 'SINGLE', 1, 0, 8500, 'Y', 'Y', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'C-501', 3, 5, 'TRIPLE', 3, 0, 6000, 'Y', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'C-502', 3, 5, 'DOUBLE', 2, 0, 7000, 'Y', 'Y', 'AVAILABLE');

-- Block D (Female) - Floors 3, 4 & 5
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'D-301', 4, 3, 'TRIPLE', 3, 0, 5000, 'N', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'D-302', 4, 3, 'DOUBLE', 2, 0, 5500, 'N', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'D-303', 4, 3, 'TRIPLE', 3, 0, 5000, 'N', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'D-401', 4, 4, 'DOUBLE', 2, 0, 6500, 'Y', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'D-402', 4, 4, 'SINGLE', 1, 0, 8500, 'Y', 'Y', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'D-501', 4, 5, 'TRIPLE', 3, 0, 6000, 'Y', 'N', 'AVAILABLE');
INSERT INTO rooms (room_id, room_number, block_id, floor_number, room_type, capacity, current_occupancy, rent_amount, ac_available, attached_bathroom, status)
VALUES (seq_rooms.NEXTVAL, 'D-502', 4, 5, 'DOUBLE', 2, 0, 7000, 'Y', 'Y', 'AVAILABLE');

-- ============================================
-- ADDITIONAL STUDENT USERS (11-20)
-- ============================================

-- Male students (11-15)
INSERT INTO users (user_id, username, email, password_hash, role, first_name, last_name, phone_number, is_active)
VALUES (seq_users.NEXTVAL, 'student011', 'dhruv.malhotra@student.edu', 'pbkdf2:sha256:260000$password123hash', 'STUDENT', 'Dhruv', 'Malhotra', '9100000011', 'Y');
INSERT INTO users (user_id, username, email, password_hash, role, first_name, last_name, phone_number, is_active)
VALUES (seq_users.NEXTVAL, 'student012', 'rohan.kapoor@student.edu', 'pbkdf2:sha256:260000$password123hash', 'STUDENT', 'Rohan', 'Kapoor', '9100000012', 'Y');
INSERT INTO users (user_id, username, email, password_hash, role, first_name, last_name, phone_number, is_active)
VALUES (seq_users.NEXTVAL, 'student013', 'siddharth.nair@student.edu', 'pbkdf2:sha256:260000$password123hash', 'STUDENT', 'Siddharth', 'Nair', '9100000013', 'Y');
INSERT INTO users (user_id, username, email, password_hash, role, first_name, last_name, phone_number, is_active)
VALUES (seq_users.NEXTVAL, 'student014', 'aditya.rao@student.edu', 'pbkdf2:sha256:260000$password123hash', 'STUDENT', 'Aditya', 'Rao', '9100000014', 'Y');
INSERT INTO users (user_id, username, email, password_hash, role, first_name, last_name, phone_number, is_active)
VALUES (seq_users.NEXTVAL, 'student015', 'nikhil.desai@student.edu', 'pbkdf2:sha256:260000$password123hash', 'STUDENT', 'Nikhil', 'Desai', '9100000015', 'Y');

-- Female students (16-20)
INSERT INTO users (user_id, username, email, password_hash, role, first_name, last_name, phone_number, is_active)
VALUES (seq_users.NEXTVAL, 'student016', 'divya.krishnan@student.edu', 'pbkdf2:sha256:260000$password123hash', 'STUDENT', 'Divya', 'Krishnan', '9100000016', 'Y');
INSERT INTO users (user_id, username, email, password_hash, role, first_name, last_name, phone_number, is_active)
VALUES (seq_users.NEXTVAL, 'student017', 'nisha.agarwal@student.edu', 'pbkdf2:sha256:260000$password123hash', 'STUDENT', 'Nisha', 'Agarwal', '9100000017', 'Y');
INSERT INTO users (user_id, username, email, password_hash, role, first_name, last_name, phone_number, is_active)
VALUES (seq_users.NEXTVAL, 'student018', 'pooja.iyer@student.edu', 'pbkdf2:sha256:260000$password123hash', 'STUDENT', 'Pooja', 'Iyer', '9100000018', 'Y');
INSERT INTO users (user_id, username, email, password_hash, role, first_name, last_name, phone_number, is_active)
VALUES (seq_users.NEXTVAL, 'student019', 'ritika.bose@student.edu', 'pbkdf2:sha256:260000$password123hash', 'STUDENT', 'Ritika', 'Bose', '9100000019', 'Y');
INSERT INTO users (user_id, username, email, password_hash, role, first_name, last_name, phone_number, is_active)
VALUES (seq_users.NEXTVAL, 'student020', 'simran.kaur@student.edu', 'pbkdf2:sha256:260000$password123hash', 'STUDENT', 'Simran', 'Kaur', '9100000020', 'Y');

-- ============================================
-- ADDITIONAL STUDENT PROFILES
-- ============================================

INSERT INTO students (student_id, user_id, roll_number, registration_number, course, branch, year_of_study, semester, batch_year, date_of_birth, gender, blood_group, permanent_address, city, state, pincode, parent_name, parent_phone, hostel_status, cgpa)
SELECT seq_students.NEXTVAL, user_id, 'CSE2021011', 'REG2021011', 'B.Tech', 'Computer Science', 3, 5, 2021, DATE '2003-02-14', 'MALE', 'B+', '12 Lotus Street', 'Delhi', 'Delhi', '110002', 'Mr. Malhotra', '9800000011', 'PENDING', 8.20
FROM users WHERE username = 'student011';

INSERT INTO students (student_id, user_id, roll_number, registration_number, course, branch, year_of_study, semester, batch_year, date_of_birth, gender, blood_group, permanent_address, city, state, pincode, parent_name, parent_phone, hostel_status, cgpa)
SELECT seq_students.NEXTVAL, user_id, 'IT2022004', 'REG2022004', 'B.Tech', 'Information Technology', 2, 3, 2022, DATE '2004-06-30', 'MALE', 'O+', '45 MG Road', 'Lucknow', 'Uttar Pradesh', '226001', 'Mr. Kapoor', '9800000012', 'PENDING', 6.50
FROM users WHERE username = 'student012';

INSERT INTO students (student_id, user_id, roll_number, registration_number, course, branch, year_of_study, semester, batch_year, date_of_birth, gender, blood_group, permanent_address, city, state, pincode, parent_name, parent_phone, hostel_status, cgpa)
SELECT seq_students.NEXTVAL, user_id, 'ME2020001', 'REG2020001', 'B.Tech', 'Mechanical', 4, 7, 2020, DATE '2002-11-08', 'MALE', 'A+', '78 Sea View', 'Kochi', 'Kerala', '682002', 'Mr. Nair', '9800000013', 'PENDING', 9.00
FROM users WHERE username = 'student013';

INSERT INTO students (student_id, user_id, roll_number, registration_number, course, branch, year_of_study, semester, batch_year, date_of_birth, gender, blood_group, permanent_address, city, state, pincode, parent_name, parent_phone, hostel_status, cgpa)
SELECT seq_students.NEXTVAL, user_id, 'ECE2021006', 'REG2021006', 'B.Tech', 'Electronics', 3, 5, 2021, DATE '2003-09-17', 'MALE', 'AB+', '90 Anna Nagar', 'Chennai', 'Tamil Nadu', '600040', 'Mr. Rao', '9800000014', 'PENDING', 5.75
FROM users WHERE username = 'student014';

INSERT INTO students (student_id, user_id, roll_number, registration_number, course, branch, year_of_study, semester, batch_year, date_of_birth, gender, blood_group, permanent_address, city, state, pincode, parent_name, parent_phone, hostel_status, cgpa)
SELECT seq_students.NEXTVAL, user_id, 'CSE2023002', 'REG2023002', 'B.Tech', 'Computer Science', 1, 1, 2023, DATE '2005-03-25', 'MALE', 'O-', '34 Patel Nagar', 'Ahmedabad', 'Gujarat', '380001', 'Mr. Desai', '9800000015', 'PENDING', 8.60
FROM users WHERE username = 'student015';

INSERT INTO students (student_id, user_id, roll_number, registration_number, course, branch, year_of_study, semester, batch_year, date_of_birth, gender, blood_group, permanent_address, city, state, pincode, parent_name, parent_phone, hostel_status, cgpa)
SELECT seq_students.NEXTVAL, user_id, 'CSE2021012', 'REG2021012', 'B.Tech', 'Computer Science', 3, 5, 2021, DATE '2003-07-04', 'FEMALE', 'A-', '56 Nungambakkam', 'Chennai', 'Tamil Nadu', '600034', 'Mr. Krishnan', '9800000016', 'PENDING', 9.20
FROM users WHERE username = 'student016';

INSERT INTO students (student_id, user_id, roll_number, registration_number, course, branch, year_of_study, semester, batch_year, date_of_birth, gender, blood_group, permanent_address, city, state, pincode, parent_name, parent_phone, hostel_status, cgpa)
SELECT seq_students.NEXTVAL, user_id, 'IT2022005', 'REG2022005', 'B.Tech', 'Information Technology', 2, 3, 2022, DATE '2004-12-19', 'FEMALE', 'B+', '23 Civil Lines', 'Allahabad', 'Uttar Pradesh', '211001', 'Mr. Agarwal', '9800000017', 'PENDING', 7.30
FROM users WHERE username = 'student017';

INSERT INTO students (student_id, user_id, roll_number, registration_number, course, branch, year_of_study, semester, batch_year, date_of_birth, gender, blood_group, permanent_address, city, state, pincode, parent_name, parent_phone, hostel_status, cgpa)
SELECT seq_students.NEXTVAL, user_id, 'ME2021002', 'REG2021002M', 'B.Tech', 'Mechanical', 3, 5, 2021, DATE '2003-04-11', 'FEMALE', 'O+', '67 Adyar', 'Chennai', 'Tamil Nadu', '600020', 'Mr. Iyer', '9800000018', 'PENDING', 6.80
FROM users WHERE username = 'student018';

INSERT INTO students (student_id, user_id, roll_number, registration_number, course, branch, year_of_study, semester, batch_year, date_of_birth, gender, blood_group, permanent_address, city, state, pincode, parent_name, parent_phone, hostel_status, cgpa)
SELECT seq_students.NEXTVAL, user_id, 'ECE2020001', 'REG2020001E', 'B.Tech', 'Electronics', 4, 7, 2020, DATE '2002-08-23', 'FEMALE', 'A+', '11 Salt Lake', 'Kolkata', 'West Bengal', '700064', 'Mr. Bose', '9800000019', 'PENDING', 8.00
FROM users WHERE username = 'student019';

INSERT INTO students (student_id, user_id, roll_number, registration_number, course, branch, year_of_study, semester, batch_year, date_of_birth, gender, blood_group, permanent_address, city, state, pincode, parent_name, parent_phone, hostel_status, cgpa)
SELECT seq_students.NEXTVAL, user_id, 'CSE2023003', 'REG2023003', 'B.Tech', 'Computer Science', 1, 1, 2023, DATE '2005-01-07', 'FEMALE', 'AB-', '88 Sector 17', 'Chandigarh', 'Punjab', '160017', 'Mr. Kaur', '9800000020', 'PENDING', 7.80
FROM users WHERE username = 'student020';

COMMIT;

-- ============================================
-- COMPATIBILITY RESPONSES (all 20 students)
-- ============================================
-- Profiles by group:
--   Early birds & quiet: student004, 006, 009, 011, 013, 016, 019
--   Night owls & social: student002, 005, 012, 014, 017, 020
--   Moderate / studious: student001, 003, 007, 008, 010, 015, 018
-- ============================================

DECLARE
    -- Question IDs resolved by display_order (MIN handles any duplicates)
    q_sleep  NUMBER;  -- 1: sleep schedule
    q_wake   NUMBER;  -- 2: wake time
    q_clean  NUMBER;  -- 3: cleanliness (SCALE 1-5)
    q_study  NUMBER;  -- 4: study habits
    q_noise  NUMBER;  -- 5: noise tolerance (SCALE 1-5)
    q_music  NUMBER;  -- 6: music preference
    q_social NUMBER;  -- 7: social habits
    q_temp   NUMBER;  -- 8: temperature
    q_share  NUMBER;  -- 9: sharing
    q_person NUMBER;  -- 10: personality
    q_smoke  NUMBER;  -- 11: smoking
    q_food   NUMBER;  -- 12: food habits

    PROCEDURE ins(p_uname VARCHAR2, p_qid NUMBER, p_val VARCHAR2, p_score NUMBER DEFAULT NULL) IS
        v_sid NUMBER;
    BEGIN
        SELECT s.student_id INTO v_sid
        FROM students s JOIN users u ON s.user_id = u.user_id
        WHERE u.username = p_uname;

        INSERT INTO compatibility_responses
            (response_id, student_id, question_id, response_value, response_score)
        VALUES
            (seq_compatibility_responses.NEXTVAL, v_sid, p_qid, p_val, p_score);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
        WHEN NO_DATA_FOUND    THEN NULL;
    END;

BEGIN
    SELECT MIN(question_id) INTO q_sleep  FROM compatibility_questions WHERE display_order = 1;
    SELECT MIN(question_id) INTO q_wake   FROM compatibility_questions WHERE display_order = 2;
    SELECT MIN(question_id) INTO q_clean  FROM compatibility_questions WHERE display_order = 3;
    SELECT MIN(question_id) INTO q_study  FROM compatibility_questions WHERE display_order = 4;
    SELECT MIN(question_id) INTO q_noise  FROM compatibility_questions WHERE display_order = 5;
    SELECT MIN(question_id) INTO q_music  FROM compatibility_questions WHERE display_order = 6;
    SELECT MIN(question_id) INTO q_social FROM compatibility_questions WHERE display_order = 7;
    SELECT MIN(question_id) INTO q_temp   FROM compatibility_questions WHERE display_order = 8;
    SELECT MIN(question_id) INTO q_share  FROM compatibility_questions WHERE display_order = 9;
    SELECT MIN(question_id) INTO q_person FROM compatibility_questions WHERE display_order = 10;
    SELECT MIN(question_id) INTO q_smoke  FROM compatibility_questions WHERE display_order = 11;
    SELECT MIN(question_id) INTO q_food   FROM compatibility_questions WHERE display_order = 12;

    -- ----------------------------------------------------------------
    -- student001 – Rahul Sharma (M) | moderate, night studier, ambivert
    -- ----------------------------------------------------------------
    ins('student001', q_sleep,  '11 PM');
    ins('student001', q_wake,   '7 AM');
    ins('student001', q_clean,  '4', 4);
    ins('student001', q_study,  'Night');
    ins('student001', q_noise,  '3', 3);
    ins('student001', q_music,  'Sometimes with headphones');
    ins('student001', q_social, 'Sometimes');
    ins('student001', q_temp,   'Moderate (AC at 24-26)');
    ins('student001', q_share,  'Most things');
    ins('student001', q_person, 'Ambivert');
    ins('student001', q_smoke,  'I prefer smoke-free environment');
    ins('student001', q_food,   'Vegetarian');

    -- ----------------------------------------------------------------
    -- student002 – Vikram Patel (M) | night owl, social, easygoing
    -- ----------------------------------------------------------------
    ins('student002', q_sleep,  '12 AM');
    ins('student002', q_wake,   '8 AM');
    ins('student002', q_clean,  '3', 3);
    ins('student002', q_study,  'Night');
    ins('student002', q_noise,  '4', 4);
    ins('student002', q_music,  'Sometimes without headphones');
    ins('student002', q_social, 'Often');
    ins('student002', q_temp,   'Warm (Fan only)');
    ins('student002', q_share,  'Yes, everything');
    ins('student002', q_person, 'Somewhat Extroverted');
    ins('student002', q_smoke,  'I dont smoke but dont mind');
    ins('student002', q_food,   'Non-Vegetarian');

    -- ----------------------------------------------------------------
    -- student003 – Arjun Singh (M) | moderate, evening studier, introverted
    -- ----------------------------------------------------------------
    ins('student003', q_sleep,  '11 PM');
    ins('student003', q_wake,   '7 AM');
    ins('student003', q_clean,  '4', 4);
    ins('student003', q_study,  'Evening');
    ins('student003', q_noise,  '3', 3);
    ins('student003', q_music,  'Sometimes with headphones');
    ins('student003', q_social, 'Rarely');
    ins('student003', q_temp,   'Moderate (AC at 24-26)');
    ins('student003', q_share,  'Some things');
    ins('student003', q_person, 'Somewhat Introverted');
    ins('student003', q_smoke,  'I prefer smoke-free environment');
    ins('student003', q_food,   'Non-Vegetarian');

    -- ----------------------------------------------------------------
    -- student004 – Karan Mehta (M) | very early bird, very clean, introvert
    -- ----------------------------------------------------------------
    ins('student004', q_sleep,  '10 PM');
    ins('student004', q_wake,   '6 AM');
    ins('student004', q_clean,  '5', 5);
    ins('student004', q_study,  'Early Morning');
    ins('student004', q_noise,  '2', 2);
    ins('student004', q_music,  'Never');
    ins('student004', q_social, 'Never');
    ins('student004', q_temp,   'Cool (AC at 21-23)');
    ins('student004', q_share,  'Some things');
    ins('student004', q_person, 'Very Introverted');
    ins('student004', q_smoke,  'I prefer smoke-free environment');
    ins('student004', q_food,   'Vegetarian');

    -- ----------------------------------------------------------------
    -- student005 – Ravi Kumar (M) | extreme night owl, messy, very social
    -- ----------------------------------------------------------------
    ins('student005', q_sleep,  'After 1 AM');
    ins('student005', q_wake,   'After 9 AM');
    ins('student005', q_clean,  '2', 2);
    ins('student005', q_study,  'Late Night');
    ins('student005', q_noise,  '5', 5);
    ins('student005', q_music,  'Often');
    ins('student005', q_social, 'Very Often');
    ins('student005', q_temp,   'Warm (Fan only)');
    ins('student005', q_share,  'Yes, everything');
    ins('student005', q_person, 'Very Extroverted');
    ins('student005', q_smoke,  'I dont smoke but dont mind');
    ins('student005', q_food,   'No preference');

    -- ----------------------------------------------------------------
    -- student006 – Priya Gupta (F) | early bird, very clean, introverted
    -- ----------------------------------------------------------------
    ins('student006', q_sleep,  '10 PM');
    ins('student006', q_wake,   '6 AM');
    ins('student006', q_clean,  '5', 5);
    ins('student006', q_study,  'Morning');
    ins('student006', q_noise,  '2', 2);
    ins('student006', q_music,  'Never');
    ins('student006', q_social, 'Rarely');
    ins('student006', q_temp,   'Cool (AC at 21-23)');
    ins('student006', q_share,  'Most things');
    ins('student006', q_person, 'Somewhat Introverted');
    ins('student006', q_smoke,  'I prefer smoke-free environment');
    ins('student006', q_food,   'Vegetarian');

    -- ----------------------------------------------------------------
    -- student007 – Anjali Verma (F) | moderate night, ambivert, sharing
    -- ----------------------------------------------------------------
    ins('student007', q_sleep,  '12 AM');
    ins('student007', q_wake,   '8 AM');
    ins('student007', q_clean,  '3', 3);
    ins('student007', q_study,  'Night');
    ins('student007', q_noise,  '4', 4);
    ins('student007', q_music,  'Sometimes without headphones');
    ins('student007', q_social, 'Sometimes');
    ins('student007', q_temp,   'Moderate (AC at 24-26)');
    ins('student007', q_share,  'Most things');
    ins('student007', q_person, 'Ambivert');
    ins('student007', q_smoke,  'I prefer smoke-free environment');
    ins('student007', q_food,   'Eggetarian');

    -- ----------------------------------------------------------------
    -- student008 – Sneha Reddy (F) | moderate, evening studier, introverted
    -- ----------------------------------------------------------------
    ins('student008', q_sleep,  '11 PM');
    ins('student008', q_wake,   '7 AM');
    ins('student008', q_clean,  '4', 4);
    ins('student008', q_study,  'Evening');
    ins('student008', q_noise,  '3', 3);
    ins('student008', q_music,  'Sometimes with headphones');
    ins('student008', q_social, 'Rarely');
    ins('student008', q_temp,   'Moderate (AC at 24-26)');
    ins('student008', q_share,  'Some things');
    ins('student008', q_person, 'Somewhat Introverted');
    ins('student008', q_smoke,  'I prefer smoke-free environment');
    ins('student008', q_food,   'Vegetarian');

    -- ----------------------------------------------------------------
    -- student009 – Meera Joshi (F) | very early, very clean, strict introvert
    -- ----------------------------------------------------------------
    ins('student009', q_sleep,  '9 PM');
    ins('student009', q_wake,   '5 AM');
    ins('student009', q_clean,  '5', 5);
    ins('student009', q_study,  'Early Morning');
    ins('student009', q_noise,  '1', 1);
    ins('student009', q_music,  'Never');
    ins('student009', q_social, 'Never');
    ins('student009', q_temp,   'Very Cool (AC at 18-20)');
    ins('student009', q_share,  'Only if asked');
    ins('student009', q_person, 'Very Introverted');
    ins('student009', q_smoke,  'I prefer smoke-free environment');
    ins('student009', q_food,   'Vegetarian');

    -- ----------------------------------------------------------------
    -- student010 – Kavya Nair (F) | moderate night, afternoon studier, extroverted
    -- ----------------------------------------------------------------
    ins('student010', q_sleep,  '12 AM');
    ins('student010', q_wake,   '9 AM');
    ins('student010', q_clean,  '3', 3);
    ins('student010', q_study,  'Afternoon');
    ins('student010', q_noise,  '4', 4);
    ins('student010', q_music,  'Sometimes without headphones');
    ins('student010', q_social, 'Often');
    ins('student010', q_temp,   'Warm (Fan only)');
    ins('student010', q_share,  'Yes, everything');
    ins('student010', q_person, 'Somewhat Extroverted');
    ins('student010', q_smoke,  'I dont smoke but dont mind');
    ins('student010', q_food,   'No preference');

    -- ----------------------------------------------------------------
    -- student011 – Dhruv Malhotra (M) | early bird, clean, moderate
    -- ----------------------------------------------------------------
    ins('student011', q_sleep,  '11 PM');
    ins('student011', q_wake,   '6 AM');
    ins('student011', q_clean,  '4', 4);
    ins('student011', q_study,  'Morning');
    ins('student011', q_noise,  '3', 3);
    ins('student011', q_music,  'Sometimes with headphones');
    ins('student011', q_social, 'Rarely');
    ins('student011', q_temp,   'Moderate (AC at 24-26)');
    ins('student011', q_share,  'Most things');
    ins('student011', q_person, 'Ambivert');
    ins('student011', q_smoke,  'I prefer smoke-free environment');
    ins('student011', q_food,   'Vegetarian');

    -- ----------------------------------------------------------------
    -- student012 – Rohan Kapoor (M) | night owl, social, music lover
    -- ----------------------------------------------------------------
    ins('student012', q_sleep,  '1 AM');
    ins('student012', q_wake,   '9 AM');
    ins('student012', q_clean,  '3', 3);
    ins('student012', q_study,  'Night');
    ins('student012', q_noise,  '4', 4);
    ins('student012', q_music,  'Sometimes without headphones');
    ins('student012', q_social, 'Often');
    ins('student012', q_temp,   'Warm (Fan only)');
    ins('student012', q_share,  'Yes, everything');
    ins('student012', q_person, 'Somewhat Extroverted');
    ins('student012', q_smoke,  'I dont smoke but dont mind');
    ins('student012', q_food,   'Non-Vegetarian');

    -- ----------------------------------------------------------------
    -- student013 – Siddharth Nair (M) | early bird, very clean, quiet introvert
    -- ----------------------------------------------------------------
    ins('student013', q_sleep,  '10 PM');
    ins('student013', q_wake,   '5 AM');
    ins('student013', q_clean,  '5', 5);
    ins('student013', q_study,  'Early Morning');
    ins('student013', q_noise,  '2', 2);
    ins('student013', q_music,  'Never');
    ins('student013', q_social, 'Never');
    ins('student013', q_temp,   'Cool (AC at 21-23)');
    ins('student013', q_share,  'Some things');
    ins('student013', q_person, 'Very Introverted');
    ins('student013', q_smoke,  'I prefer smoke-free environment');
    ins('student013', q_food,   'Vegetarian');

    -- ----------------------------------------------------------------
    -- student014 – Aditya Rao (M) | extreme night owl, messy, very loud
    -- ----------------------------------------------------------------
    ins('student014', q_sleep,  'After 1 AM');
    ins('student014', q_wake,   'After 9 AM');
    ins('student014', q_clean,  '2', 2);
    ins('student014', q_study,  'Late Night');
    ins('student014', q_noise,  '5', 5);
    ins('student014', q_music,  'Often');
    ins('student014', q_social, 'Very Often');
    ins('student014', q_temp,   'Warm (Fan only)');
    ins('student014', q_share,  'Yes, everything');
    ins('student014', q_person, 'Very Extroverted');
    ins('student014', q_smoke,  'I smoke');
    ins('student014', q_food,   'Non-Vegetarian');

    -- ----------------------------------------------------------------
    -- student015 – Nikhil Desai (M) | moderate, evening, ambivert
    -- ----------------------------------------------------------------
    ins('student015', q_sleep,  '12 AM');
    ins('student015', q_wake,   '7 AM');
    ins('student015', q_clean,  '4', 4);
    ins('student015', q_study,  'Evening');
    ins('student015', q_noise,  '3', 3);
    ins('student015', q_music,  'Sometimes with headphones');
    ins('student015', q_social, 'Sometimes');
    ins('student015', q_temp,   'Moderate (AC at 24-26)');
    ins('student015', q_share,  'Some things');
    ins('student015', q_person, 'Ambivert');
    ins('student015', q_smoke,  'I prefer smoke-free environment');
    ins('student015', q_food,   'No preference');

    -- ----------------------------------------------------------------
    -- student016 – Divya Krishnan (F) | early bird, very clean, strict introvert
    -- ----------------------------------------------------------------
    ins('student016', q_sleep,  '10 PM');
    ins('student016', q_wake,   '6 AM');
    ins('student016', q_clean,  '5', 5);
    ins('student016', q_study,  'Early Morning');
    ins('student016', q_noise,  '2', 2);
    ins('student016', q_music,  'Never');
    ins('student016', q_social, 'Never');
    ins('student016', q_temp,   'Cool (AC at 21-23)');
    ins('student016', q_share,  'Most things');
    ins('student016', q_person, 'Somewhat Introverted');
    ins('student016', q_smoke,  'I prefer smoke-free environment');
    ins('student016', q_food,   'Vegetarian');

    -- ----------------------------------------------------------------
    -- student017 – Nisha Agarwal (F) | night owl, social, music
    -- ----------------------------------------------------------------
    ins('student017', q_sleep,  '1 AM');
    ins('student017', q_wake,   '9 AM');
    ins('student017', q_clean,  '3', 3);
    ins('student017', q_study,  'Night');
    ins('student017', q_noise,  '4', 4);
    ins('student017', q_music,  'Sometimes without headphones');
    ins('student017', q_social, 'Often');
    ins('student017', q_temp,   'Warm (Fan only)');
    ins('student017', q_share,  'Yes, everything');
    ins('student017', q_person, 'Somewhat Extroverted');
    ins('student017', q_smoke,  'I dont smoke but dont mind');
    ins('student017', q_food,   'Non-Vegetarian');

    -- ----------------------------------------------------------------
    -- student018 – Pooja Iyer (F) | moderate, evening studier, ambivert
    -- ----------------------------------------------------------------
    ins('student018', q_sleep,  '11 PM');
    ins('student018', q_wake,   '7 AM');
    ins('student018', q_clean,  '4', 4);
    ins('student018', q_study,  'Evening');
    ins('student018', q_noise,  '3', 3);
    ins('student018', q_music,  'Sometimes with headphones');
    ins('student018', q_social, 'Sometimes');
    ins('student018', q_temp,   'Moderate (AC at 24-26)');
    ins('student018', q_share,  'Some things');
    ins('student018', q_person, 'Ambivert');
    ins('student018', q_smoke,  'I prefer smoke-free environment');
    ins('student018', q_food,   'Vegetarian');

    -- ----------------------------------------------------------------
    -- student019 – Ritika Bose (F) | early bird, clean, quiet
    -- ----------------------------------------------------------------
    ins('student019', q_sleep,  '11 PM');
    ins('student019', q_wake,   '7 AM');
    ins('student019', q_clean,  '4', 4);
    ins('student019', q_study,  'Morning');
    ins('student019', q_noise,  '3', 3);
    ins('student019', q_music,  'Sometimes with headphones');
    ins('student019', q_social, 'Rarely');
    ins('student019', q_temp,   'Moderate (AC at 24-26)');
    ins('student019', q_share,  'Most things');
    ins('student019', q_person, 'Ambivert');
    ins('student019', q_smoke,  'I prefer smoke-free environment');
    ins('student019', q_food,   'Vegetarian');

    -- ----------------------------------------------------------------
    -- student020 – Simran Kaur (F) | night owl, social, loud
    -- ----------------------------------------------------------------
    ins('student020', q_sleep,  'After 1 AM');
    ins('student020', q_wake,   'After 9 AM');
    ins('student020', q_clean,  '2', 2);
    ins('student020', q_study,  'Late Night');
    ins('student020', q_noise,  '5', 5);
    ins('student020', q_music,  'Often');
    ins('student020', q_social, 'Often');
    ins('student020', q_temp,   'Warm (Fan only)');
    ins('student020', q_share,  'Most things');
    ins('student020', q_person, 'Very Extroverted');
    ins('student020', q_smoke,  'I dont smoke but dont mind');
    ins('student020', q_food,   'Eggetarian');

    -- ----------------------------------------------------------------
    -- Mark compatibility_completed = 'Y' for all 20 students
    -- ----------------------------------------------------------------
    UPDATE students SET compatibility_completed = 'Y'
    WHERE user_id IN (
        SELECT user_id FROM users
        WHERE username IN (
            'student001','student002','student003','student004','student005',
            'student006','student007','student008','student009','student010',
            'student011','student012','student013','student014','student015',
            'student016','student017','student018','student019','student020'
        )
    );

    COMMIT;
END;
/

-- ============================================
-- SUMMARY
-- ============================================
SELECT 'Users: '       || COUNT(*) AS summary FROM users     UNION ALL
SELECT 'Students: '    || COUNT(*)             FROM students  UNION ALL
SELECT 'Rooms: '       || COUNT(*)             FROM rooms     UNION ALL
SELECT 'Quiz done: '   || COUNT(*)             FROM students WHERE compatibility_completed = 'Y';
