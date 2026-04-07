-- ============================================
-- MIGRATION: CGPA Tracking + Block Cutoffs + Room Preferences
-- Run this once against an existing database.
-- ============================================

-- 1. Add CGPA to students
ALTER TABLE students ADD cgpa NUMBER(4,2);
ALTER TABLE students ADD CONSTRAINT chk_cgpa CHECK (cgpa BETWEEN 0 AND 10);

-- 2. Add CGPA cutoff to hostel_blocks (0 = no cutoff, open to all)
ALTER TABLE hostel_blocks ADD cgpa_cutoff NUMBER(4,2) DEFAULT 0;
ALTER TABLE hostel_blocks ADD CONSTRAINT chk_cgpa_cutoff CHECK (cgpa_cutoff BETWEEN 0 AND 10);

-- 3. Room Preferences table (students rank up to 3 blocks)
CREATE TABLE room_preferences (
    preference_id   NUMBER(10) PRIMARY KEY,
    student_id      NUMBER(10) NOT NULL,
    block_id        NUMBER(10) NOT NULL,
    preference_rank NUMBER(1)  NOT NULL CHECK (preference_rank BETWEEN 1 AND 3),
    notes           VARCHAR2(500),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_rp_student FOREIGN KEY (student_id) REFERENCES students(student_id),
    CONSTRAINT fk_rp_block   FOREIGN KEY (block_id)   REFERENCES hostel_blocks(block_id),
    CONSTRAINT uk_rp_student_rank  UNIQUE (student_id, preference_rank),
    CONSTRAINT uk_rp_student_block UNIQUE (student_id, block_id)
);

CREATE SEQUENCE seq_room_preferences START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

COMMIT;
