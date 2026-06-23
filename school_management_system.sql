-- ============================================================
--  SCHOOL MANAGEMENT SYSTEM (SMS) — Uganda MoES / NCDC
--  Target:  MySQL 8.0+
--  Scope:   Primary P1–P7  |  Lower Secondary S1–S4
--  Author:  Database Developer Intern
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- ============================================================
-- 1. ACADEMIC STRUCTURE
-- ============================================================

CREATE TABLE IF NOT EXISTS classes (
    class_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    class_name      VARCHAR(30)  NOT NULL,          -- e.g. P3, S2 WEST
    stream          VARCHAR(20)  DEFAULT NULL,       -- EAST / WEST / NULL for single-stream
    level           ENUM('Primary','Secondary')  NOT NULL,
    capacity        TINYINT UNSIGNED NOT NULL DEFAULT 45,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_class_stream (class_name, stream)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS terms (
    term_id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    term_name       ENUM('Term 1','Term 2','Term 3') NOT NULL,
    academic_year   YEAR        NOT NULL,
    start_date      DATE        NOT NULL,
    end_date        DATE        NOT NULL,
    is_active       TINYINT(1)  NOT NULL DEFAULT 0,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_term_year (term_name, academic_year),
    CONSTRAINT chk_term_dates CHECK (end_date > start_date)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS subjects (
    subject_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    subject_name    VARCHAR(60)  NOT NULL,
    subject_code    VARCHAR(10)  NOT NULL,           -- MTH, ENG, PHY …
    level           ENUM('Primary','Secondary','Both') NOT NULL DEFAULT 'Both',
    is_active       TINYINT(1)  NOT NULL DEFAULT 1,
    UNIQUE KEY uq_subject_code (subject_code)
) ENGINE=InnoDB;

-- ============================================================
-- 2. STUDENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS students (
    student_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_number  VARCHAR(20)  NOT NULL,
    first_name      VARCHAR(50)  NOT NULL,
    last_name       VARCHAR(50)  NOT NULL,
    other_names     VARCHAR(50)  DEFAULT NULL,
    gender          ENUM('Male','Female') NOT NULL,
    date_of_birth   DATE         NOT NULL,
    class_id        INT UNSIGNED NOT NULL,
    enrollment_date DATE         NOT NULL,
    status          ENUM('Active','Inactive','Transferred','Expelled','Completed') NOT NULL DEFAULT 'Active',
    religion        VARCHAR(40)  DEFAULT NULL,
    nationality     VARCHAR(40)  DEFAULT 'Ugandan',
    photo_path      VARCHAR(255) DEFAULT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_student_number (student_number),
    CONSTRAINT fk_student_class FOREIGN KEY (class_id) REFERENCES classes (class_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS student_contacts (
    contact_id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id          INT UNSIGNED NOT NULL,
    guardian_first_name VARCHAR(50)  NOT NULL,
    guardian_last_name  VARCHAR(50)  NOT NULL,
    relationship        ENUM('Father','Mother','Guardian','Sibling','Other') NOT NULL,
    phone_primary       VARCHAR(20)  NOT NULL,
    phone_secondary     VARCHAR(20)  DEFAULT NULL,
    email               VARCHAR(100) DEFAULT NULL,
    address             TEXT         DEFAULT NULL,
    is_emergency_contact TINYINT(1) NOT NULL DEFAULT 0,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_contact_student FOREIGN KEY (student_id) REFERENCES students (student_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 3. STAFF
-- ============================================================

CREATE TABLE IF NOT EXISTS staff (
    staff_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    staff_number    VARCHAR(20)  NOT NULL,
    first_name      VARCHAR(50)  NOT NULL,
    last_name       VARCHAR(50)  NOT NULL,
    other_names     VARCHAR(50)  DEFAULT NULL,
    gender          ENUM('Male','Female') NOT NULL,
    date_of_birth   DATE         DEFAULT NULL,
    role            ENUM('Head Teacher','Deputy Head Teacher','Teacher','Bursar','Admin','Librarian','Nurse','Security','Support Staff') NOT NULL,
    phone           VARCHAR(20)  NOT NULL,
    email           VARCHAR(100) DEFAULT NULL,
    hire_date       DATE         NOT NULL,
    qualification   VARCHAR(100) DEFAULT NULL,
    status          ENUM('Active','On Leave','Terminated','Retired') NOT NULL DEFAULT 'Active',
    photo_path      VARCHAR(255) DEFAULT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_staff_number (staff_number)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS class_teacher (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    class_id        INT UNSIGNED NOT NULL,
    staff_id        INT UNSIGNED NOT NULL,
    term_id         INT UNSIGNED NOT NULL,
    assigned_date   DATE         NOT NULL,
    UNIQUE KEY uq_class_term (class_id, term_id),
    CONSTRAINT fk_ct_class  FOREIGN KEY (class_id)  REFERENCES classes (class_id),
    CONSTRAINT fk_ct_staff  FOREIGN KEY (staff_id)  REFERENCES staff   (staff_id),
    CONSTRAINT fk_ct_term   FOREIGN KEY (term_id)   REFERENCES terms   (term_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS subject_teacher (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    staff_id        INT UNSIGNED NOT NULL,
    subject_id      INT UNSIGNED NOT NULL,
    class_id        INT UNSIGNED NOT NULL,
    term_id         INT UNSIGNED NOT NULL,
    UNIQUE KEY uq_subj_teacher (staff_id, subject_id, class_id, term_id),
    CONSTRAINT fk_st_staff   FOREIGN KEY (staff_id)   REFERENCES staff    (staff_id),
    CONSTRAINT fk_st_subject FOREIGN KEY (subject_id) REFERENCES subjects (subject_id),
    CONSTRAINT fk_st_class   FOREIGN KEY (class_id)   REFERENCES classes  (class_id),
    CONSTRAINT fk_st_term    FOREIGN KEY (term_id)    REFERENCES terms    (term_id)
) ENGINE=InnoDB;

-- ============================================================
-- 4. FEES & PAYMENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS fee_structure (
    structure_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    class_id        INT UNSIGNED NOT NULL,
    fee_name        VARCHAR(60)  NOT NULL,            -- Tuition, PTA, Transport, Sports …
    description     TEXT         DEFAULT NULL,
    is_mandatory    TINYINT(1)   NOT NULL DEFAULT 1,
    term_id         INT UNSIGNED NOT NULL,
    amount          DECIMAL(10,2) NOT NULL,
    UNIQUE KEY uq_fee_structure (class_id, fee_name, term_id),
    CONSTRAINT fk_fs_class   FOREIGN KEY (class_id) REFERENCES classes (class_id),
    CONSTRAINT fk_fs_term    FOREIGN KEY (term_id)  REFERENCES terms   (term_id),
    CONSTRAINT chk_fs_amount CHECK (amount >= 0)
) ENGINE=InnoDB;

-- Unique payment code issued per student for tracking all their transactions
CREATE TABLE IF NOT EXISTS student_payment_codes (
    spc_id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id      INT UNSIGNED NOT NULL,
    payment_code    VARCHAR(30)  NOT NULL,           -- e.g. SPC-2025-00341
    issued_date     DATE         NOT NULL,
    is_active       TINYINT(1)   NOT NULL DEFAULT 1,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_payment_code (payment_code),
    UNIQUE KEY uq_student_code (student_id),        -- one active code per student
    CONSTRAINT fk_spc_student FOREIGN KEY (student_id) REFERENCES students (student_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS payments (
    payment_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    spc_id          INT UNSIGNED NOT NULL,           -- links to student via payment code
    term_id         INT UNSIGNED NOT NULL,
    fee_name        VARCHAR(60)  NOT NULL,           -- matches fee_structure.fee_name
    amount_paid     DECIMAL(10,2) NOT NULL,
    payment_date    DATE          NOT NULL,
    payment_method  ENUM('Cash','Mobile Money','Bank','Cheque') NOT NULL,
    reference_number VARCHAR(60) DEFAULT NULL,
    notes           TEXT         DEFAULT NULL,
    recorded_by     INT UNSIGNED NOT NULL,           -- staff_id of bursar/admin
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pay_spc     FOREIGN KEY (spc_id)      REFERENCES student_payment_codes (spc_id),
    CONSTRAINT fk_pay_term    FOREIGN KEY (term_id)     REFERENCES terms                 (term_id),
    CONSTRAINT fk_pay_staff   FOREIGN KEY (recorded_by) REFERENCES staff                (staff_id),
    CONSTRAINT chk_pay_amount CHECK (amount_paid > 0)
) ENGINE=InnoDB;

-- ============================================================
-- 5. ATTENDANCE
-- ============================================================

CREATE TABLE IF NOT EXISTS attendance (
    attendance_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id      INT UNSIGNED NOT NULL,
    class_id        INT UNSIGNED NOT NULL,
    term_id         INT UNSIGNED NOT NULL,
    attendance_date DATE         NOT NULL,
    status          ENUM('Present','Absent','Late','Excused') NOT NULL,
    remarks         VARCHAR(200) DEFAULT NULL,
    recorded_by     INT UNSIGNED NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_attendance (student_id, attendance_date),
    CONSTRAINT fk_att_student FOREIGN KEY (student_id)  REFERENCES students (student_id),
    CONSTRAINT fk_att_class   FOREIGN KEY (class_id)    REFERENCES classes  (class_id),
    CONSTRAINT fk_att_term    FOREIGN KEY (term_id)     REFERENCES terms    (term_id),
    CONSTRAINT fk_att_staff   FOREIGN KEY (recorded_by) REFERENCES staff    (staff_id)
) ENGINE=InnoDB;

-- ============================================================
-- 6. EXAMS & RESULTS
-- ============================================================

CREATE TABLE IF NOT EXISTS exams (
    exam_id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    exam_name       VARCHAR(80)  NOT NULL,
    exam_type       ENUM('End of Term','Continuous Assessment','Mock','UNEB','Internal') NOT NULL,
    term_id         INT UNSIGNED NOT NULL,
    class_id        INT UNSIGNED NOT NULL,
    exam_date       DATE         DEFAULT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_exam_term  FOREIGN KEY (term_id)  REFERENCES terms   (term_id),
    CONSTRAINT fk_exam_class FOREIGN KEY (class_id) REFERENCES classes (class_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS exam_results (
    result_id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    exam_id         INT UNSIGNED NOT NULL,
    student_id      INT UNSIGNED NOT NULL,
    subject_id      INT UNSIGNED NOT NULL,
    marks_obtained  DECIMAL(6,2) NOT NULL,
    total_marks     DECIMAL(6,2) NOT NULL DEFAULT 100,
    grade           VARCHAR(5)   DEFAULT NULL,       -- A, B, C … or D1–F9 for UCE
    remarks         VARCHAR(200) DEFAULT NULL,
    entered_by      INT UNSIGNED NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_result (exam_id, student_id, subject_id),
    CONSTRAINT fk_res_exam    FOREIGN KEY (exam_id)    REFERENCES exams    (exam_id),
    CONSTRAINT fk_res_student FOREIGN KEY (student_id) REFERENCES students (student_id),
    CONSTRAINT fk_res_subject FOREIGN KEY (subject_id) REFERENCES subjects (subject_id),
    CONSTRAINT fk_res_staff   FOREIGN KEY (entered_by) REFERENCES staff    (staff_id),
    CONSTRAINT chk_res_marks  CHECK (marks_obtained >= 0 AND marks_obtained <= total_marks)
) ENGINE=InnoDB;

-- Grade boundaries stored per exam type for flexible configuration
CREATE TABLE IF NOT EXISTS grade_boundaries (
    boundary_id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    exam_type       ENUM('End of Term','Continuous Assessment','Mock','UNEB','Internal') NOT NULL,
    level           ENUM('Primary','Secondary') NOT NULL,
    grade           VARCHAR(5)   NOT NULL,
    min_mark        DECIMAL(5,2) NOT NULL,
    max_mark        DECIMAL(5,2) NOT NULL,
    UNIQUE KEY uq_boundary (exam_type, level, grade)
) ENGINE=InnoDB;

-- ============================================================
-- 7. TIMETABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS timetable_slots (
    slot_id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    class_id        INT UNSIGNED NOT NULL,
    subject_id      INT UNSIGNED NOT NULL,
    staff_id        INT UNSIGNED NOT NULL,
    term_id         INT UNSIGNED NOT NULL,
    day_of_week     ENUM('Monday','Tuesday','Wednesday','Thursday','Friday') NOT NULL,
    period_number   TINYINT UNSIGNED NOT NULL,       -- 1–8
    start_time      TIME         NOT NULL,
    end_time        TIME         NOT NULL,
    room            VARCHAR(30)  DEFAULT NULL,
    UNIQUE KEY uq_slot (class_id, term_id, day_of_week, period_number),
    CONSTRAINT fk_tt_class   FOREIGN KEY (class_id)   REFERENCES classes  (class_id),
    CONSTRAINT fk_tt_subject FOREIGN KEY (subject_id) REFERENCES subjects (subject_id),
    CONSTRAINT fk_tt_staff   FOREIGN KEY (staff_id)   REFERENCES staff    (staff_id),
    CONSTRAINT fk_tt_term    FOREIGN KEY (term_id)    REFERENCES terms    (term_id)
) ENGINE=InnoDB;

-- ============================================================
-- 8. LIBRARY
-- ============================================================

CREATE TABLE IF NOT EXISTS books (
    book_id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    isbn            VARCHAR(20)  DEFAULT NULL,
    title           VARCHAR(200) NOT NULL,
    author          VARCHAR(150) NOT NULL,
    publisher       VARCHAR(100) DEFAULT NULL,
    publish_year    YEAR         DEFAULT NULL,
    subject_id      INT UNSIGNED DEFAULT NULL,
    copies_total    SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    copies_available SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    shelf_location  VARCHAR(30)  DEFAULT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_book_subject FOREIGN KEY (subject_id) REFERENCES subjects (subject_id),
    CONSTRAINT chk_copies CHECK (copies_available <= copies_total)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS book_loans (
    loan_id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    book_id         INT UNSIGNED NOT NULL,
    borrower_type   ENUM('Student','Staff') NOT NULL,
    borrower_student_id INT UNSIGNED DEFAULT NULL,
    borrower_staff_id   INT UNSIGNED DEFAULT NULL,
    loan_date       DATE         NOT NULL,
    due_date        DATE         NOT NULL,
    return_date     DATE         DEFAULT NULL,
    fine_amount     DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    fine_paid       TINYINT(1)   NOT NULL DEFAULT 0,
    issued_by       INT UNSIGNED NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_loan_book    FOREIGN KEY (book_id)              REFERENCES books    (book_id),
    CONSTRAINT fk_loan_student FOREIGN KEY (borrower_student_id)  REFERENCES students (student_id),
    CONSTRAINT fk_loan_staff   FOREIGN KEY (borrower_staff_id)    REFERENCES staff    (staff_id),
    CONSTRAINT fk_loan_issuer  FOREIGN KEY (issued_by)            REFERENCES staff    (staff_id),
    CONSTRAINT chk_borrower    CHECK (
        (borrower_type = 'Student' AND borrower_student_id IS NOT NULL AND borrower_staff_id IS NULL) OR
        (borrower_type = 'Staff'   AND borrower_staff_id   IS NOT NULL AND borrower_student_id IS NULL)
    )
) ENGINE=InnoDB;

-- ============================================================
-- 9. DORMITORY (Boarding School Support)
-- ============================================================

CREATE TABLE IF NOT EXISTS dormitories (
    dormitory_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    dorm_name       VARCHAR(60)  NOT NULL,
    gender          ENUM('Male','Female','Mixed') NOT NULL,
    capacity        SMALLINT UNSIGNED NOT NULL,
    warden_staff_id INT UNSIGNED DEFAULT NULL,
    CONSTRAINT fk_dorm_warden FOREIGN KEY (warden_staff_id) REFERENCES staff (staff_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS dormitory_allocations (
    allocation_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id      INT UNSIGNED NOT NULL,
    dormitory_id    INT UNSIGNED NOT NULL,
    term_id         INT UNSIGNED NOT NULL,
    bed_number      VARCHAR(10)  DEFAULT NULL,
    allocated_date  DATE         NOT NULL,
    UNIQUE KEY uq_dorm_alloc (student_id, term_id),
    CONSTRAINT fk_da_student FOREIGN KEY (student_id)   REFERENCES students    (student_id),
    CONSTRAINT fk_da_dorm    FOREIGN KEY (dormitory_id) REFERENCES dormitories (dormitory_id),
    CONSTRAINT fk_da_term    FOREIGN KEY (term_id)      REFERENCES terms       (term_id)
) ENGINE=InnoDB;

-- ============================================================
-- 10. DISCIPLINE
-- ============================================================

CREATE TABLE IF NOT EXISTS discipline_categories (
    category_id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_name   VARCHAR(80)  NOT NULL,
    severity        ENUM('Minor','Moderate','Serious','Gross') NOT NULL,
    UNIQUE KEY uq_disc_cat (category_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS discipline_records (
    record_id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id      INT UNSIGNED NOT NULL,
    category_id     INT UNSIGNED NOT NULL,
    incident_date   DATE         NOT NULL,
    description     TEXT         NOT NULL,
    action_taken    TEXT         DEFAULT NULL,
    reported_by     INT UNSIGNED NOT NULL,
    approved_by     INT UNSIGNED DEFAULT NULL,
    status          ENUM('Pending','Resolved','Appealed') NOT NULL DEFAULT 'Pending',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_disc_student  FOREIGN KEY (student_id)  REFERENCES students              (student_id),
    CONSTRAINT fk_disc_category FOREIGN KEY (category_id) REFERENCES discipline_categories (category_id),
    CONSTRAINT fk_disc_reporter FOREIGN KEY (reported_by) REFERENCES staff                (staff_id),
    CONSTRAINT fk_disc_approver FOREIGN KEY (approved_by) REFERENCES staff                (staff_id)
) ENGINE=InnoDB;

-- ============================================================
-- 11. COMMUNICATION & NOTICES
-- ============================================================

CREATE TABLE IF NOT EXISTS notices (
    notice_id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title           VARCHAR(200) NOT NULL,
    content         TEXT         NOT NULL,
    audience        ENUM('Students','Parents','Staff','All') NOT NULL DEFAULT 'All',
    level_target    ENUM('Primary','Secondary','All')         NOT NULL DEFAULT 'All',
    posted_date     DATE         NOT NULL,
    expiry_date     DATE         DEFAULT NULL,
    posted_by       INT UNSIGNED NOT NULL,
    is_published    TINYINT(1)   NOT NULL DEFAULT 1,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notice_staff FOREIGN KEY (posted_by) REFERENCES staff (staff_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS sms_messages (
    sms_id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    recipient_phone VARCHAR(20)  NOT NULL,
    recipient_type  ENUM('Parent','Staff') NOT NULL,
    message_body    TEXT         NOT NULL,
    status          ENUM('Pending','Sent','Failed') NOT NULL DEFAULT 'Pending',
    sent_at         TIMESTAMP    DEFAULT NULL,
    sent_by         INT UNSIGNED NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sms_staff FOREIGN KEY (sent_by) REFERENCES staff (staff_id)
) ENGINE=InnoDB;

-- ============================================================
-- 12. USER MANAGEMENT (System Login & RBAC)
-- ============================================================

CREATE TABLE IF NOT EXISTS roles (
    role_id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    role_name       VARCHAR(40)  NOT NULL,
    description     VARCHAR(200) DEFAULT NULL,
    UNIQUE KEY uq_role_name (role_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS permissions (
    permission_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    permission_name VARCHAR(80)  NOT NULL,           -- e.g. 'view_results', 'edit_fees'
    module          VARCHAR(40)  NOT NULL,            -- e.g. 'Exams', 'Finance'
    UNIQUE KEY uq_perm (permission_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS role_permissions (
    role_id         INT UNSIGNED NOT NULL,
    permission_id   INT UNSIGNED NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    CONSTRAINT fk_rp_role FOREIGN KEY (role_id)       REFERENCES roles       (role_id) ON DELETE CASCADE,
    CONSTRAINT fk_rp_perm FOREIGN KEY (permission_id) REFERENCES permissions (permission_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS users (
    user_id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username        VARCHAR(50)  NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    role_id         INT UNSIGNED NOT NULL,
    staff_id        INT UNSIGNED DEFAULT NULL,        -- NULL for admin-only accounts
    is_active       TINYINT(1)   NOT NULL DEFAULT 1,
    last_login      TIMESTAMP    DEFAULT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_username (username),
    CONSTRAINT fk_usr_role  FOREIGN KEY (role_id)  REFERENCES roles (role_id),
    CONSTRAINT fk_usr_staff FOREIGN KEY (staff_id) REFERENCES staff (staff_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS audit_logs (
    log_id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         INT UNSIGNED  NOT NULL,
    action          VARCHAR(100)  NOT NULL,           -- 'CREATE','UPDATE','DELETE'
    table_name      VARCHAR(60)   NOT NULL,
    record_id       INT UNSIGNED  DEFAULT NULL,
    old_values      JSON          DEFAULT NULL,
    new_values      JSON          DEFAULT NULL,
    ip_address      VARCHAR(45)   DEFAULT NULL,
    logged_at       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_log_user FOREIGN KEY (user_id) REFERENCES users (user_id)
) ENGINE=InnoDB;

-- ============================================================
-- 13. HEALTH / MEDICAL RECORDS
-- ============================================================

CREATE TABLE IF NOT EXISTS medical_records (
    record_id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id      INT UNSIGNED NOT NULL,
    record_date     DATE         NOT NULL,
    complaint       TEXT         NOT NULL,
    diagnosis       TEXT         DEFAULT NULL,
    treatment       TEXT         DEFAULT NULL,
    referred        TINYINT(1)   NOT NULL DEFAULT 0,
    referral_notes  TEXT         DEFAULT NULL,
    recorded_by     INT UNSIGNED NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_med_student FOREIGN KEY (student_id)  REFERENCES students (student_id),
    CONSTRAINT fk_med_staff   FOREIGN KEY (recorded_by) REFERENCES staff    (staff_id)
) ENGINE=InnoDB;

-- ============================================================
-- 14. TRANSPORT
-- ============================================================

CREATE TABLE IF NOT EXISTS routes (
    route_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    route_name      VARCHAR(80)  NOT NULL,
    description     TEXT         DEFAULT NULL,
    driver_name     VARCHAR(100) DEFAULT NULL,
    driver_phone    VARCHAR(20)  DEFAULT NULL,
    vehicle_plate   VARCHAR(20)  DEFAULT NULL,
    UNIQUE KEY uq_route_name (route_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS student_transport (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id      INT UNSIGNED NOT NULL,
    route_id        INT UNSIGNED NOT NULL,
    term_id         INT UNSIGNED NOT NULL,
    UNIQUE KEY uq_student_route_term (student_id, term_id),
    CONSTRAINT fk_tr_student FOREIGN KEY (student_id) REFERENCES students (student_id),
    CONSTRAINT fk_tr_route   FOREIGN KEY (route_id)   REFERENCES routes   (route_id),
    CONSTRAINT fk_tr_term    FOREIGN KEY (term_id)    REFERENCES terms    (term_id)
) ENGINE=InnoDB;

-- ============================================================
-- SEED DATA — Core reference tables
-- ============================================================

-- Uganda NCDC Primary Subjects
INSERT IGNORE INTO subjects (subject_name, subject_code, level) VALUES
('English Language',             'ENG',  'Both'),
('Mathematics',                  'MTH',  'Both'),
('Science',                      'SCI',  'Primary'),
('Social Studies & RE',          'SST',  'Primary'),
('Kiswahili',                    'KSW',  'Both'),
('Luganda / Local Language',     'LUG',  'Primary'),
('Creative and Performing Arts', 'CPA',  'Primary'),
('Physical Education',           'PE',   'Both'),
('Biology',                      'BIO',  'Secondary'),
('Chemistry',                    'CHM',  'Secondary'),
('Physics',                      'PHY',  'Secondary'),
('History',                      'HIS',  'Secondary'),
('Geography',                    'GEO',  'Secondary'),
('Christian Religious Education','CRE',  'Secondary'),
('Computer Studies',             'CMP',  'Both'),
('Agriculture',                  'AGR',  'Secondary'),
('Fine Art',                     'FAT',  'Secondary'),
('Commerce',                     'COM',  'Secondary'),
('Entrepreneurship',             'ENT',  'Secondary');

-- Discipline categories
INSERT IGNORE INTO discipline_categories (category_name, severity) VALUES
('Lateness',                  'Minor'),
('Incomplete uniform',        'Minor'),
('Disrespect to staff',       'Moderate'),
('Bullying / fighting',       'Serious'),
('Cheating in exams',         'Serious'),
('Vandalism',                 'Serious'),
('Drug/substance use',        'Gross'),
('Theft',                     'Gross'),
('Sexual misconduct',         'Gross'),
('Absenteeism',               'Moderate');

-- Roles
INSERT IGNORE INTO roles (role_name, description) VALUES
('Super Admin',    'Full system access'),
('Head Teacher',   'School-wide oversight'),
('Class Teacher',  'Class and student management'),
('Bursar',         'Fees and financial records'),
('Librarian',      'Library management'),
('Nurse',          'Medical records');

-- Permissions (sample)
INSERT IGNORE INTO permissions (permission_name, module) VALUES
('view_students',      'Students'),
('edit_students',      'Students'),
('view_fees',          'Finance'),
('edit_fees',          'Finance'),
('post_results',       'Exams'),
('view_results',       'Exams'),
('manage_attendance',  'Attendance'),
('manage_library',     'Library'),
('post_notices',       'Communication'),
('manage_users',       'System');

-- Grant all permissions to Super Admin (role_id = 1)
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT 1, permission_id FROM permissions;

-- Primary classes P1–P7
INSERT IGNORE INTO classes (class_name, stream, level, capacity) VALUES
('P1', NULL, 'Primary', 50), ('P2', NULL, 'Primary', 50),
('P3', NULL, 'Primary', 50), ('P4', NULL, 'Primary', 50),
('P5', NULL, 'Primary', 48), ('P6', NULL, 'Primary', 48),
('P7', NULL, 'Primary', 45);

-- Secondary classes S1–S4 (East & West streams)
INSERT IGNORE INTO classes (class_name, stream, level, capacity) VALUES
('S1', 'EAST', 'Secondary', 45), ('S1', 'WEST', 'Secondary', 45),
('S2', 'EAST', 'Secondary', 45), ('S2', 'WEST', 'Secondary', 45),
('S3', 'EAST', 'Secondary', 40), ('S3', 'WEST', 'Secondary', 40),
('S4', 'EAST', 'Secondary', 40), ('S4', 'WEST', 'Secondary', 40);

-- Current term
INSERT IGNORE INTO terms (term_name, academic_year, start_date, end_date, is_active) VALUES
('Term 1', 2025, '2025-02-03', '2025-04-11', 0),
('Term 2', 2025, '2025-05-12', '2025-08-08', 0),
('Term 3', 2025, '2025-09-08', '2025-11-28', 1);

-- UCE Grade Boundaries (O-Level Secondary)
INSERT IGNORE INTO grade_boundaries (exam_type, level, grade, min_mark, max_mark) VALUES
('End of Term', 'Secondary', 'D1', 80, 100),
('End of Term', 'Secondary', 'D2', 75,  79),
('End of Term', 'Secondary', 'C3', 70,  74),
('End of Term', 'Secondary', 'C4', 65,  69),
('End of Term', 'Secondary', 'C5', 60,  64),
('End of Term', 'Secondary', 'C6', 55,  59),
('End of Term', 'Secondary', 'P7', 50,  54),
('End of Term', 'Secondary', 'P8', 40,  49),
('End of Term', 'Secondary', 'F9',  0,  39);

-- PLE Grade Boundaries (Primary)
INSERT IGNORE INTO grade_boundaries (exam_type, level, grade, min_mark, max_mark) VALUES
('End of Term', 'Primary', 'Distinction', 75, 100),
('End of Term', 'Primary', 'Credit',      60,  74),
('End of Term', 'Primary', 'Pass',        50,  59),
('End of Term', 'Primary', 'Fail',         0,  49);

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- USEFUL VIEWS
-- ============================================================

CREATE OR REPLACE VIEW vw_student_fee_balances AS
SELECT
    s.student_id,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    s.student_number,
    spc.payment_code,
    c.class_name,
    t.term_name,
    t.academic_year,
    fs.fee_name,
    fs.amount                                      AS amount_due,
    COALESCE(SUM(p.amount_paid), 0)                AS amount_paid,
    fs.amount - COALESCE(SUM(p.amount_paid), 0)    AS balance
FROM students s
JOIN classes              c   ON c.class_id    = s.class_id
JOIN student_payment_codes spc ON spc.student_id = s.student_id
JOIN fee_structure         fs  ON fs.class_id   = s.class_id
JOIN terms                 t   ON t.term_id     = fs.term_id
LEFT JOIN payments         p   ON p.spc_id      = spc.spc_id
                              AND p.term_id     = fs.term_id
                              AND p.fee_name    = fs.fee_name
WHERE s.status = 'Active'
GROUP BY s.student_id, spc.spc_id, fs.fee_name, fs.term_id;

CREATE OR REPLACE VIEW vw_student_results_summary AS
SELECT
    s.student_id,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    s.student_number,
    c.class_name,
    e.exam_name,
    e.exam_type,
    t.term_name,
    t.academic_year,
    sub.subject_name,
    er.marks_obtained,
    er.total_marks,
    ROUND((er.marks_obtained / er.total_marks) * 100, 1) AS percentage,
    er.grade
FROM exam_results er
JOIN students s   ON s.student_id   = er.student_id
JOIN exams    e   ON e.exam_id      = er.exam_id
JOIN subjects sub ON sub.subject_id = er.subject_id
JOIN classes  c   ON c.class_id     = e.class_id
JOIN terms    t   ON t.term_id      = e.term_id;

CREATE OR REPLACE VIEW vw_attendance_summary AS
SELECT
    s.student_id,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    c.class_name,
    t.term_name,
    t.academic_year,
    COUNT(*)                                             AS total_days,
    SUM(a.status = 'Present')                            AS days_present,
    SUM(a.status = 'Absent')                             AS days_absent,
    SUM(a.status = 'Late')                               AS days_late,
    ROUND(SUM(a.status = 'Present') / COUNT(*) * 100, 1) AS attendance_pct
FROM attendance a
JOIN students s ON s.student_id = a.student_id
JOIN classes  c ON c.class_id   = a.class_id
JOIN terms    t ON t.term_id    = a.term_id
GROUP BY s.student_id, a.class_id, a.term_id;

-- ============================================================
-- END OF SCHEMA
-- ============================================================
