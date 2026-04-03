-- ============================================
-- HOSTEL MANAGEMENT SYSTEM - FUNCTIONS
-- Oracle PL/SQL Functions
-- ============================================
-- ============================================
-- FUNCTION: Calculate Compatibility Score
-- Calculates compatibility percentage between two students
-- ============================================
CREATE OR REPLACE FUNCTION func_calculate_compatibility (
    p_student1_id   IN NUMBER,
    p_student2_id   IN NUMBER
) RETURN NUMBER
IS
    v_total_weight      NUMBER := 0;
    v_matched_weight    NUMBER := 0;
    v_score             NUMBER := 0;
    
    CURSOR c_questions IS
        SELECT question_id, category, weight_percentage
        FROM compatibility_questions
        WHERE is_active = 'Y';
    
    v_response1 VARCHAR2(500);
    v_response2 VARCHAR2(500);
BEGIN
    -- Check if both students have completed the questionnaire
    DECLARE
        v_completed1 CHAR(1);
        v_completed2 CHAR(1);
    BEGIN
        SELECT compatibility_completed INTO v_completed1
        FROM students WHERE student_id = p_student1_id;
        
        SELECT compatibility_completed INTO v_completed2
        FROM students WHERE student_id = p_student2_id;
        
        IF v_completed1 = 'N' OR v_completed2 = 'N' THEN
            RETURN -1;  -- Indicates incomplete questionnaire
        END IF;
    END;
    
    -- Calculate compatibility
    FOR q IN c_questions LOOP
        v_total_weight := v_total_weight + q.weight_percentage;
        
        BEGIN
            SELECT response_value INTO v_response1
            FROM compatibility_responses
            WHERE student_id = p_student1_id AND question_id = q.question_id;
            
            SELECT response_value INTO v_response2
            FROM compatibility_responses
            WHERE student_id = p_student2_id AND question_id = q.question_id;
            
            -- Compare responses
            IF v_response1 = v_response2 THEN
                v_matched_weight := v_matched_weight + q.weight_percentage;
            ELSIF q.category IN ('SLEEP_SCHEDULE', 'WAKE_TIME') THEN
                -- Partial match for time-based questions (within 1 hour)
                IF ABS(TO_NUMBER(REGEXP_SUBSTR(v_response1, '\d+')) - 
                       TO_NUMBER(REGEXP_SUBSTR(v_response2, '\d+'))) <= 1 THEN
                    v_matched_weight := v_matched_weight + (q.weight_percentage * 0.7);
                ELSIF ABS(TO_NUMBER(REGEXP_SUBSTR(v_response1, '\d+')) - 
                         TO_NUMBER(REGEXP_SUBSTR(v_response2, '\d+'))) <= 2 THEN
                    v_matched_weight := v_matched_weight + (q.weight_percentage * 0.4);
                END IF;
            ELSIF q.category IN ('CLEANLINESS', 'NOISE_TOLERANCE', 'SOCIAL_HABITS') THEN
                -- Partial match for scale-based questions
                IF ABS(TO_NUMBER(v_response1) - TO_NUMBER(v_response2)) <= 1 THEN
                    v_matched_weight := v_matched_weight + (q.weight_percentage * 0.6);
                END IF;
            END IF;
            
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- Question not answered by one or both students
                v_total_weight := v_total_weight - q.weight_percentage;
        END;
    END LOOP;
    
    -- Calculate final score
    IF v_total_weight > 0 THEN
        v_score := ROUND((v_matched_weight / v_total_weight) * 100, 2);
    ELSE
        v_score := 0;
    END IF;
    
    RETURN v_score;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN -2;  -- Indicates error
END func_calculate_compatibility;
/
-- ============================================
-- FUNCTION: Get Compatibility Category
-- Returns category based on score
-- ============================================
CREATE OR REPLACE FUNCTION func_get_compatibility_category (
    p_score IN NUMBER
) RETURN VARCHAR2
IS
BEGIN
    RETURN CASE 
        WHEN p_score >= 85 THEN 'Excellent Match'
        WHEN p_score >= 70 THEN 'Good Match'
        WHEN p_score >= 50 THEN 'Moderate Match'
        WHEN p_score >= 0 THEN 'Poor Match'
        ELSE 'Unknown'
    END;
END func_get_compatibility_category;
/
-- ============================================
-- FUNCTION: Calculate Available Room Capacity
-- Returns number of available beds in a block
-- ============================================
CREATE OR REPLACE FUNCTION func_available_capacity (
    p_block_id IN NUMBER DEFAULT NULL
) RETURN NUMBER
IS
    v_available NUMBER;
BEGIN
    SELECT NVL(SUM(r.capacity - r.current_occupancy), 0)
    INTO v_available
    FROM rooms r
    WHERE r.status IN ('AVAILABLE', 'OCCUPIED')
    AND (p_block_id IS NULL OR r.block_id = p_block_id);
    
    RETURN v_available;
END func_available_capacity;
/
-- ============================================
-- FUNCTION: Calculate Total Pending Fine Amount
-- Returns total pending fines for a student
-- ============================================
CREATE OR REPLACE FUNCTION func_pending_fines (
    p_student_id IN NUMBER
) RETURN NUMBER
IS
    v_total NUMBER;
BEGIN
    SELECT NVL(SUM(amount - paid_amount), 0)
    INTO v_total
    FROM fines
    WHERE student_id = p_student_id
    AND status IN ('PENDING', 'OVERDUE', 'PARTIALLY_PAID');
    
    RETURN v_total;
END func_pending_fines;
/
-- ============================================
-- FUNCTION: Get Occupancy Percentage
-- Returns occupancy percentage for block or overall
-- ============================================
CREATE OR REPLACE FUNCTION func_occupancy_percentage (
    p_block_id IN NUMBER DEFAULT NULL
) RETURN NUMBER
IS
    v_total_capacity    NUMBER;
    v_current_occupancy NUMBER;
BEGIN
    SELECT NVL(SUM(capacity), 0), NVL(SUM(current_occupancy), 0)
    INTO v_total_capacity, v_current_occupancy
    FROM rooms
    WHERE status != 'MAINTENANCE'
    AND (p_block_id IS NULL OR block_id = p_block_id);
    
    IF v_total_capacity = 0 THEN
        RETURN 0;
    END IF;
    
    RETURN ROUND((v_current_occupancy / v_total_capacity) * 100, 2);
END func_occupancy_percentage;
/
-- ============================================
-- FUNCTION: Get Complaint Count for Student
-- Returns count of complaints by status
-- ============================================
CREATE OR REPLACE FUNCTION func_complaint_count (
    p_student_id    IN NUMBER,
    p_status        IN VARCHAR2 DEFAULT NULL
) RETURN NUMBER
IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM complaints
    WHERE student_id = p_student_id
    AND (p_status IS NULL OR status = p_status);
    
    RETURN v_count;
END func_complaint_count;
/
-- ============================================
-- FUNCTION: Check Room Availability
-- Returns Y/N based on room availability
-- ============================================
CREATE OR REPLACE FUNCTION func_is_room_available (
    p_room_id IN NUMBER
) RETURN CHAR
IS
    v_capacity      NUMBER;
    v_occupancy     NUMBER;
    v_status        VARCHAR2(20);
BEGIN
    SELECT capacity, current_occupancy, status
    INTO v_capacity, v_occupancy, v_status
    FROM rooms
    WHERE room_id = p_room_id;
    
    IF v_status IN ('AVAILABLE', 'OCCUPIED') AND v_occupancy < v_capacity THEN
        RETURN 'Y';
    ELSE
        RETURN 'N';
    END IF;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'N';
END func_is_room_available;
/
-- ============================================
-- FUNCTION: Get Best Roommate Matches
-- Returns comma-separated list of best match student IDs
-- ============================================
CREATE OR REPLACE FUNCTION func_get_best_matches (
    p_student_id    IN NUMBER,
    p_limit         IN NUMBER DEFAULT 5,
    p_gender_match  IN CHAR DEFAULT 'Y'
) RETURN VARCHAR2
IS
    v_result    VARCHAR2(4000) := '';
    v_gender    VARCHAR2(10);
    v_score     NUMBER;
    
    CURSOR c_candidates IS
        SELECT s.student_id, s.roll_number
        FROM students s
        WHERE s.student_id != p_student_id
        AND s.compatibility_completed = 'Y'
        AND s.hostel_status = 'PENDING'
        AND (p_gender_match = 'N' OR s.gender = v_gender)
        ORDER BY s.student_id;
    
    TYPE t_match IS RECORD (
        student_id  NUMBER,
        score       NUMBER
    );
    TYPE t_matches IS TABLE OF t_match INDEX BY PLS_INTEGER;
    v_matches t_matches;
    v_idx NUMBER := 0;
BEGIN
    -- Get requesting student's gender
    SELECT gender INTO v_gender
    FROM students WHERE student_id = p_student_id;
    
    -- Calculate scores for all candidates
    FOR cand IN c_candidates LOOP
        v_score := func_calculate_compatibility(p_student_id, cand.student_id);
        IF v_score >= 0 THEN
            v_idx := v_idx + 1;
            v_matches(v_idx).student_id := cand.student_id;
            v_matches(v_idx).score := v_score;
        END IF;
    END LOOP;
    
    -- Sort and get top matches (simple bubble sort)
    FOR i IN 1..LEAST(v_idx, p_limit) LOOP
        FOR j IN i+1..v_idx LOOP
            IF v_matches(j).score > v_matches(i).score THEN
                DECLARE
                    v_temp t_match;
                BEGIN
                    v_temp := v_matches(i);
                    v_matches(i) := v_matches(j);
                    v_matches(j) := v_temp;
                END;
            END IF;
        END LOOP;
        
        IF i <= p_limit THEN
            v_result := v_result || v_matches(i).student_id || ':' || v_matches(i).score;
            IF i < LEAST(v_idx, p_limit) THEN
                v_result := v_result || ',';
            END IF;
        END IF;
    END LOOP;
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN '';
END func_get_best_matches;
/
-- ============================================
-- FUNCTION: Generate Room Number
-- Generates formatted room number
-- ============================================
CREATE OR REPLACE FUNCTION func_generate_room_number (
    p_block_id      IN NUMBER,
    p_floor_number  IN NUMBER,
    p_room_sequence IN NUMBER
) RETURN VARCHAR2
IS
    v_block_code VARCHAR2(10);
BEGIN
    SELECT SUBSTR(block_name, 1, 1)
    INTO v_block_code
    FROM hostel_blocks
    WHERE block_id = p_block_id;
    
    RETURN v_block_code || '-' || p_floor_number || LPAD(p_room_sequence, 2, '0');
END func_generate_room_number;
/
-- ============================================
-- FUNCTION: Get Average Resolution Time
-- Returns average complaint resolution time in hours
-- ============================================
CREATE OR REPLACE FUNCTION func_avg_resolution_time (
    p_block_id      IN NUMBER DEFAULT NULL,
    p_category_id   IN NUMBER DEFAULT NULL,
    p_days_back     IN NUMBER DEFAULT 30
) RETURN NUMBER
IS
    v_avg_hours NUMBER;
BEGIN
    SELECT NVL(AVG(
        ROUND((CAST(resolved_at AS DATE) - CAST(created_at AS DATE)) * 24, 2)
    ), 0)
    INTO v_avg_hours
    FROM complaints c
    JOIN students s ON c.student_id = s.student_id
    LEFT JOIN rooms r ON s.room_id = r.room_id
    WHERE c.resolved_at IS NOT NULL
    AND c.created_at >= SYSDATE - p_days_back
    AND (p_block_id IS NULL OR r.block_id = p_block_id)
    AND (p_category_id IS NULL OR c.category_id = p_category_id);
    
    RETURN v_avg_hours;
END func_avg_resolution_time;
/
