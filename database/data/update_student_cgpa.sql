-- ============================================
-- Seed CGPA values for existing sample students
-- Run after 05_alter_cgpa_preferences.sql
-- ============================================
UPDATE students SET cgpa = 8.75 WHERE roll_number = 'CSE2021001';
UPDATE students SET cgpa = 7.20 WHERE roll_number = 'CSE2021002';
UPDATE students SET cgpa = 6.85 WHERE roll_number = 'ECE2021003';
UPDATE students SET cgpa = 9.10 WHERE roll_number = 'ME2022001';
UPDATE students SET cgpa = 5.90 WHERE roll_number = 'CE2022002';
UPDATE students SET cgpa = 8.45 WHERE roll_number = 'CSE2021004';
UPDATE students SET cgpa = 7.65 WHERE roll_number = 'ECE2021005';
UPDATE students SET cgpa = 6.30 WHERE roll_number = 'IT2022003';
UPDATE students SET cgpa = 8.90 WHERE roll_number = 'CSE2023001';
UPDATE students SET cgpa = 7.00 WHERE roll_number = 'ECE2023002';
COMMIT;
