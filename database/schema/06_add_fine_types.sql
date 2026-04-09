-- ============================================
-- MIGRATION: Add new fine types for warden
-- Run once against an existing database.
-- ============================================

-- Drop the existing check constraint on fines.fine_type
-- (Oracle requires dropping then re-adding to modify check constraints)
DECLARE
    v_constraint_name VARCHAR2(100);
BEGIN
    SELECT constraint_name INTO v_constraint_name
    FROM user_constraints
    WHERE table_name = 'FINES'
      AND constraint_type = 'C'
      AND search_condition LIKE '%fine_type%';
    EXECUTE IMMEDIATE 'ALTER TABLE fines DROP CONSTRAINT ' || v_constraint_name;
EXCEPTION
    WHEN NO_DATA_FOUND THEN NULL;
END;
/

-- Re-add the check constraint with the new fine types
ALTER TABLE fines ADD CONSTRAINT chk_fine_type CHECK (
    fine_type IN (
        'LATE_ENTRY',
        'DAMAGE',
        'RULE_VIOLATION',
        'MESS_WASTE',
        'ELECTRICITY',
        'OTHER',
        'NOT_DONE_BIOMETRIC',
        'BEHAVIOURAL_CONDUCT',
        'SUBSTANCE_CONSUMPTION',
        'INQUIRY'
    )
);

COMMIT;
