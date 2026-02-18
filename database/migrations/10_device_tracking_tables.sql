-- ============================================
-- RentComPro Migration #10
-- Device Live Tracking Tables
-- Date: February 18, 2026
-- Run this in Supabase SQL Editor
-- ============================================

-- ============================================
-- STEP 1: Modify DEVICES table
-- Add client_id + SUPERWATCH/NORMAL tracking mode
-- ============================================

ALTER TABLE devices
    ADD COLUMN IF NOT EXISTS client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS tracking_mode VARCHAR(15) DEFAULT 'NORMAL',
    ADD COLUMN IF NOT EXISTS superwatch_reason TEXT,
    ADD COLUMN IF NOT EXISTS superwatch_activated_at TIMESTAMP WITH TIME ZONE,
    ADD COLUMN IF NOT EXISTS alert_count INTEGER DEFAULT 0;

ALTER TABLE devices
    DROP CONSTRAINT IF EXISTS check_tracking_mode;

ALTER TABLE devices
    ADD CONSTRAINT check_tracking_mode
    CHECK (tracking_mode IN ('NORMAL', 'SUPERWATCH'));

CREATE INDEX IF NOT EXISTS idx_devices_client_id
    ON devices(client_id);

CREATE INDEX IF NOT EXISTS idx_devices_tracking_mode
    ON devices(tracking_mode);

-- ============================================
-- STEP 2: Modify HARDWARE_STATS table
-- Add all new monitoring columns
-- ============================================

ALTER TABLE hardware_stats
    ADD COLUMN IF NOT EXISTS cpu_temp DECIMAL(5,1),
    ADD COLUMN IF NOT EXISTS hdd_temp DECIMAL(5,1),
    ADD COLUMN IF NOT EXISTS uptime_minutes INTEGER,
    ADD COLUMN IF NOT EXISTS restart_count_24h INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS active_window TEXT,
    ADD COLUMN IF NOT EXISTS tracking_mode VARCHAR(15) DEFAULT 'NORMAL',
    ADD COLUMN IF NOT EXISTS ram_usage DECIMAL(5,2),
    ADD COLUMN IF NOT EXISTS disk_usage DECIMAL(5,2),
    ADD COLUMN IF NOT EXISTS last_boot TIMESTAMP WITH TIME ZONE,
    ADD COLUMN IF NOT EXISTS connection_type VARCHAR(20),
    ADD COLUMN IF NOT EXISTS computer_name VARCHAR(100),
    ADD COLUMN IF NOT EXISTS logged_in_user VARCHAR(100),
    ADD COLUMN IF NOT EXISTS lan_mac_address VARCHAR(20),
    ADD COLUMN IF NOT EXISTS active_mac_address VARCHAR(20),
    ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT true;

CREATE INDEX IF NOT EXISTS idx_hardware_stats_mode
    ON hardware_stats(tracking_mode);

CREATE INDEX IF NOT EXISTS idx_hardware_stats_online
    ON hardware_stats(is_online);

-- ============================================
-- STEP 3: Create DEVICE_EVENTS table
-- ============================================

CREATE TABLE IF NOT EXISTS device_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,
    -- RESTART           → system restarted (Event ID 6005)
    -- ABRUPT_SHUTDOWN   → unexpected shutdown (Event ID 6008)
    -- USER_CHANGE       → different username logged in
    -- MAC_CHANGE        → active MAC address changed (dongle swap?)
    -- IP_CHANGE         → IP address changed
    -- LOCATION_CHANGE   → IP geo suggests different city
    -- OFFLINE_SPIKE     → offline during business hours
    -- NIGHT_ACTIVITY    → active between configured night hours
    -- USB_CONNECT       → USB device plugged in
    -- SUPERWATCH_ON     → SUPERWATCH mode activated
    -- SUPERWATCH_OFF    → SUPERWATCH mode deactivated
    -- PAYMENT_OVERDUE   → invoice overdue threshold crossed
    event_data JSONB,
    -- event_data examples:
    -- MAC_CHANGE:      {"old_mac": "AA:BB:CC", "new_mac": "DD:EE:FF"}
    -- IP_CHANGE:       {"old_ip": "192.168.1.5", "new_ip": "10.0.0.2"}
    -- USER_CHANGE:     {"old_user": "rahul", "new_user": "unknown"}
    -- PAYMENT_OVERDUE: {"invoice_number": "RENT/FEB/001", "overdue_days": 7}
    -- RESTART:         {"restart_count_24h": 6}
    severity VARCHAR(20) NOT NULL DEFAULT 'INFO',
    is_resolved BOOLEAN DEFAULT false,
    resolved_by UUID REFERENCES users(id),
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolve_note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT check_event_severity CHECK (severity IN ('INFO', 'WARNING', 'CRITICAL')),
    CONSTRAINT check_event_type CHECK (event_type IN (
        'RESTART', 'ABRUPT_SHUTDOWN', 'USER_CHANGE', 'MAC_CHANGE',
        'IP_CHANGE', 'LOCATION_CHANGE', 'OFFLINE_SPIKE', 'NIGHT_ACTIVITY',
        'USB_CONNECT', 'SUPERWATCH_ON', 'SUPERWATCH_OFF', 'PAYMENT_OVERDUE'
    ))
);

CREATE INDEX IF NOT EXISTS idx_device_events_device
    ON device_events(device_id);

CREATE INDEX IF NOT EXISTS idx_device_events_severity
    ON device_events(severity);

CREATE INDEX IF NOT EXISTS idx_device_events_resolved
    ON device_events(is_resolved);

CREATE INDEX IF NOT EXISTS idx_device_events_created
    ON device_events(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_device_events_type
    ON device_events(event_type);

-- Composite index: unresolved critical events per device (dashboard query)
CREATE INDEX IF NOT EXISTS idx_device_events_unresolved_critical
    ON device_events(device_id, is_resolved, severity)
    WHERE is_resolved = false;

-- ============================================
-- STEP 4: Create DEVICE_SCREENSHOTS table
-- ============================================

CREATE TABLE IF NOT EXISTS device_screenshots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    screenshot_data TEXT NOT NULL,  -- base64 JPEG, compressed
    file_size_kb INTEGER,
    width INTEGER DEFAULT 1024,
    height INTEGER DEFAULT 768,
    triggered_by VARCHAR(20) NOT NULL DEFAULT 'AUTO_SUPERWATCH',
    -- AUTO_SUPERWATCH → automatic in SUPERWATCH mode
    -- MANUAL          → admin requested
    active_window TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT check_triggered_by CHECK (triggered_by IN ('AUTO_SUPERWATCH', 'MANUAL'))
);

CREATE INDEX IF NOT EXISTS idx_screenshots_device
    ON device_screenshots(device_id);

CREATE INDEX IF NOT EXISTS idx_screenshots_created
    ON device_screenshots(created_at DESC);

-- ============================================
-- STEP 5: Create SYSTEM_SETTINGS table
-- All configurable settings — editable from dashboard
-- ============================================

CREATE TABLE IF NOT EXISTS system_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT NOT NULL,
    setting_type VARCHAR(20) NOT NULL DEFAULT 'STRING',
    -- STRING, INTEGER, BOOLEAN, DECIMAL
    category VARCHAR(50) NOT NULL DEFAULT 'GENERAL',
    -- SUPERWATCH, NORMAL, HEURISTIC, ALERTS, BUSINESS_HOURS
    label VARCHAR(200) NOT NULL,
    description TEXT,
    min_value TEXT,
    max_value TEXT,
    updated_by UUID REFERENCES users(id),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_system_settings_category
    ON system_settings(category);

-- ============================================
-- STEP 6: Create SETTINGS_HISTORY table
-- Audit trail — who changed what and when
-- ============================================

CREATE TABLE IF NOT EXISTS settings_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    setting_key VARCHAR(100) NOT NULL,
    old_value TEXT,
    new_value TEXT NOT NULL,
    changed_by UUID REFERENCES users(id),
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    change_note TEXT
);

CREATE INDEX IF NOT EXISTS idx_settings_history_key
    ON settings_history(setting_key);

CREATE INDEX IF NOT EXISTS idx_settings_history_changed_at
    ON settings_history(changed_at DESC);

-- Auto-log setting changes via trigger
CREATE OR REPLACE FUNCTION log_setting_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only log if value actually changed
    IF OLD.setting_value IS DISTINCT FROM NEW.setting_value THEN
        INSERT INTO settings_history
            (setting_key, old_value, new_value, changed_by, changed_at)
        VALUES
            (NEW.setting_key, OLD.setting_value, NEW.setting_value, NEW.updated_by, NOW());
    END IF;
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_log_setting_change ON system_settings;

CREATE TRIGGER trigger_log_setting_change
    BEFORE UPDATE ON system_settings
    FOR EACH ROW
    EXECUTE FUNCTION log_setting_change();

-- ============================================
-- STEP 7: Insert default settings
-- ============================================

INSERT INTO system_settings
    (setting_key, setting_value, setting_type, category, label, description, min_value, max_value)
VALUES

-- ── SUPERWATCH MODE ───────────────────────────────────────────────────────

('superwatch_report_interval_seconds', '30', 'INTEGER', 'SUPERWATCH',
 'Report Interval (seconds)',
 'Kitne seconds par device backend ko data bhejega SUPERWATCH mode mein. Kam = jyada load.',
 '10', '300'),

('superwatch_screenshot_interval_minutes', '5', 'INTEGER', 'SUPERWATCH',
 'Screenshot Interval (minutes)',
 'Kitne minutes par screenshot lega. 1 min = bahut jyada data. 5 min = balanced.',
 '1', '60'),

('superwatch_screenshot_quality', '30', 'INTEGER', 'SUPERWATCH',
 'Screenshot JPEG Quality (1-100)',
 'Quality 30 = ~50-80KB file. Quality 80 = ~300KB. i5 2nd gen ke liye 30 recommended.',
 '10', '80'),

('superwatch_screenshot_max_width', '1024', 'INTEGER', 'SUPERWATCH',
 'Screenshot Max Width (pixels)',
 'Screenshot is size par resize hoga. 1024 = readable + light. 1920 = full HD but heavy.',
 '640', '1920'),

('superwatch_max_screenshots_per_device', '10', 'INTEGER', 'SUPERWATCH',
 'Max Screenshots Stored per Device',
 'Ek device ke liye maximum kitne screenshots DB mein rahenge. Limit ke baad purane delete.',
 '5', '100'),

('superwatch_screenshot_retention_days', '30', 'INTEGER', 'SUPERWATCH',
 'Screenshot Retention (days)',
 'Screenshots kitne dino tak store rahenge. Purane auto-delete ho jayenge.',
 '7', '365'),

-- ── NORMAL MODE ───────────────────────────────────────────────────────────

('normal_report_interval_seconds', '300', 'INTEGER', 'NORMAL',
 'Report Interval (seconds)',
 'Kitne seconds par data bhejega NORMAL mode mein. Default 300 = 5 minutes.',
 '60', '1800'),

('normal_stats_retention_hours', '24', 'INTEGER', 'NORMAL',
 'Stats Retention (hours)',
 'Hardware stats kitne ghante DB mein rahenge. Purane time-based delete honge.',
 '6', '168'),

-- ── BUSINESS HOURS ────────────────────────────────────────────────────────

('business_hours_start', '9', 'INTEGER', 'BUSINESS_HOURS',
 'Business Hours Start (0-23)',
 'Kab se business hours shuru. Default: 9 AM. OFFLINE_SPIKE is time ke baad check hoga.',
 '0', '12'),

('business_hours_end', '19', 'INTEGER', 'BUSINESS_HOURS',
 'Business Hours End (0-23)',
 'Kab tak business hours. Default: 7 PM. Is time ke baad offline = normal.',
 '13', '23'),

('business_days', '1,2,3,4,5,6', 'STRING', 'BUSINESS_HOURS',
 'Business Days (1=Mon, 7=Sun)',
 'Comma separated. Default: Mon-Sat. In dino mein offline hona suspicious hai.',
 NULL, NULL),

-- ── HEURISTIC ENGINE ─────────────────────────────────────────────────────

('heuristic_enabled', 'true', 'BOOLEAN', 'HEURISTIC',
 'Auto-SUPERWATCH Enable/Disable',
 'Kya system automatically SUPERWATCH mode activate kare suspicious activity par?',
 NULL, NULL),

('heuristic_payment_overdue_days', '5', 'INTEGER', 'HEURISTIC',
 'Payment Overdue Trigger (days)',
 'Invoice kitne din overdue hone par SUPERWATCH auto-activate hoga.',
 '1', '30'),

('heuristic_offline_hours_trigger', '4', 'INTEGER', 'HEURISTIC',
 'Offline Duration Trigger (hours)',
 'Business hours mein kitne ghante lagatar offline rahe to WARNING alert aaye.',
 '1', '24'),

('heuristic_restart_count_trigger', '5', 'INTEGER', 'HEURISTIC',
 'Restart Count Trigger (per 24 hours)',
 '24 ghante mein kitne restarts par SUPERWATCH auto-activate hoga.',
 '2', '20'),

('heuristic_abrupt_shutdown_trigger', '3', 'INTEGER', 'HEURISTIC',
 'Abrupt Shutdown Trigger (per 24 hours)',
 '24 ghante mein kitne abrupt shutdowns par SUPERWATCH auto-activate hoga.',
 '1', '10'),

('heuristic_night_start_hour', '23', 'INTEGER', 'HEURISTIC',
 'Night Hours Start (0-23)',
 'Is time ke baad activity suspicious maani jayegi. Default: 11 PM.',
 '20', '23'),

('heuristic_night_end_hour', '6', 'INTEGER', 'HEURISTIC',
 'Night Hours End (0-23)',
 'Is time se pehle activity suspicious. Default: 6 AM.',
 '4', '9'),

-- ── ALERTS ────────────────────────────────────────────────────────────────

('alert_sms_enabled', 'false', 'BOOLEAN', 'ALERTS',
 'SMS Alerts Enable/Disable',
 'CRITICAL alerts par SMS bheja jaye? (Phase 2 feature — abhi disabled)',
 NULL, NULL),

('alert_whatsapp_enabled', 'false', 'BOOLEAN', 'ALERTS',
 'WhatsApp Alerts Enable/Disable',
 'CRITICAL alerts par WhatsApp message? (Phase 2 feature — abhi disabled)',
 NULL, NULL),

('alert_admin_phone', '', 'STRING', 'ALERTS',
 'Admin Phone Number',
 'SMS/WhatsApp alerts is number par aayenge. Format: 9876543210 (no +91)',
 NULL, NULL),

('alert_events_retention_days', '90', 'INTEGER', 'ALERTS',
 'Event Log Retention (days)',
 'Device events kitne dino tak store rahenge. Purane auto-delete.',
 '30', '365')

ON CONFLICT (setting_key) DO NOTHING;

-- ============================================
-- STEP 8: Dynamic cleanup function for screenshots
-- Reads limit from system_settings (not hardcoded)
-- ============================================

CREATE OR REPLACE FUNCTION cleanup_old_screenshots()
RETURNS TRIGGER AS $$
DECLARE
    max_count INTEGER;
    retention_days INTEGER;
BEGIN
    -- Read limit from settings (default 10 if not found)
    SELECT COALESCE(NULLIF(setting_value, '')::INTEGER, 10)
    INTO max_count
    FROM system_settings
    WHERE setting_key = 'superwatch_max_screenshots_per_device';

    -- Delete beyond max count per device
    DELETE FROM device_screenshots
    WHERE device_id = NEW.device_id
    AND id NOT IN (
        SELECT id FROM device_screenshots
        WHERE device_id = NEW.device_id
        ORDER BY created_at DESC
        LIMIT max_count
    );

    -- Also delete screenshots older than retention days
    SELECT COALESCE(NULLIF(setting_value, '')::INTEGER, 30)
    INTO retention_days
    FROM system_settings
    WHERE setting_key = 'superwatch_screenshot_retention_days';

    DELETE FROM device_screenshots
    WHERE device_id = NEW.device_id
    AND created_at < NOW() - (retention_days || ' days')::INTERVAL;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_cleanup_screenshots ON device_screenshots;

CREATE TRIGGER trigger_cleanup_screenshots
    AFTER INSERT ON device_screenshots
    FOR EACH ROW
    EXECUTE FUNCTION cleanup_old_screenshots();

-- ============================================
-- STEP 9: Dynamic cleanup for hardware_stats
-- Time-based (not count-based) using settings
-- ============================================

CREATE OR REPLACE FUNCTION cleanup_old_hardware_stats()
RETURNS TRIGGER AS $$
DECLARE
    retention_hours INTEGER;
    cutoff_time TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Read retention hours from settings
    -- Use different retention for NORMAL vs SUPERWATCH
    IF NEW.tracking_mode = 'SUPERWATCH' THEN
        -- SUPERWATCH: keep 48 hours (more data needed for investigation)
        retention_hours := 48;
    ELSE
        SELECT COALESCE(NULLIF(setting_value, '')::INTEGER, 24)
        INTO retention_hours
        FROM system_settings
        WHERE setting_key = 'normal_stats_retention_hours';
    END IF;

    cutoff_time := NOW() - (retention_hours || ' hours')::INTERVAL;

    -- Delete old records for this device beyond retention period
    DELETE FROM hardware_stats
    WHERE device_id = NEW.device_id
    AND timestamp < cutoff_time;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_cleanup_hardware_stats ON hardware_stats;

CREATE TRIGGER trigger_cleanup_hardware_stats
    AFTER INSERT ON hardware_stats
    FOR EACH ROW
    EXECUTE FUNCTION cleanup_old_hardware_stats();

-- ============================================
-- STEP 10: Dynamic cleanup for device_events
-- Respects alert_events_retention_days setting
-- ============================================

CREATE OR REPLACE FUNCTION cleanup_old_device_events()
RETURNS TRIGGER AS $$
DECLARE
    retention_days INTEGER;
BEGIN
    SELECT COALESCE(NULLIF(setting_value, '')::INTEGER, 90)
    INTO retention_days
    FROM system_settings
    WHERE setting_key = 'alert_events_retention_days';

    -- Only delete resolved events beyond retention
    -- Unresolved events are NEVER auto-deleted
    DELETE FROM device_events
    WHERE device_id = NEW.device_id
    AND is_resolved = true
    AND created_at < NOW() - (retention_days || ' days')::INTERVAL;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_cleanup_device_events ON device_events;

CREATE TRIGGER trigger_cleanup_device_events
    AFTER INSERT ON device_events
    FOR EACH ROW
    EXECUTE FUNCTION cleanup_old_device_events();

-- ============================================
-- STEP 11: device_live_status VIEW (fixed)
-- Properly joins client via devices.client_id
-- ============================================

DROP VIEW IF EXISTS device_live_status;

CREATE OR REPLACE VIEW device_live_status AS
SELECT
    d.id,
    d.serial_number,
    d.device_type,
    d.brand,
    d.model,
    d.tracking_mode,
    d.superwatch_reason,
    d.superwatch_activated_at,
    d.alert_count,
    d.status AS device_status,
    -- Latest hardware stats (LATERAL = most recent row only, efficient)
    hs.cpu_usage,
    hs.ram_usage,
    hs.disk_usage,
    hs.cpu_temp,
    hs.hdd_temp,
    hs.is_online,
    hs.logged_in_user,
    hs.ip_address,
    hs.lan_mac_address,
    hs.active_mac_address,
    hs.connection_type,
    hs.computer_name,
    hs.uptime_minutes,
    hs.last_boot,
    hs.restart_count_24h,
    hs.active_window,
    hs.timestamp AS last_seen,
    -- Online/offline with time context
    CASE
        WHEN hs.timestamp IS NULL THEN 'NEVER_SEEN'
        WHEN hs.is_online = true AND hs.timestamp > NOW() - INTERVAL '10 minutes' THEN 'ONLINE'
        WHEN hs.timestamp > NOW() - INTERVAL '1 hour' THEN 'RECENTLY_ONLINE'
        WHEN hs.timestamp > NOW() - INTERVAL '24 hours' THEN 'OFFLINE'
        ELSE 'LONG_OFFLINE'
    END AS online_status,
    -- How long offline (null if online)
    CASE
        WHEN hs.is_online = false OR hs.timestamp < NOW() - INTERVAL '10 minutes'
        THEN EXTRACT(EPOCH FROM (NOW() - hs.timestamp)) / 60
        ELSE NULL
    END AS offline_minutes,
    -- Unresolved WARNING + CRITICAL alerts count
    (
        SELECT COUNT(*)
        FROM device_events de
        WHERE de.device_id = d.id
        AND de.is_resolved = false
        AND de.severity IN ('WARNING', 'CRITICAL')
    ) AS unresolved_alerts,
    -- Most recent unresolved critical event
    (
        SELECT event_type
        FROM device_events de
        WHERE de.device_id = d.id
        AND de.is_resolved = false
        AND de.severity = 'CRITICAL'
        ORDER BY de.created_at DESC
        LIMIT 1
    ) AS latest_critical_event,
    -- Client info (via client_id on devices)
    c.id AS client_id,
    c.company_name,
    c.owner_name,
    c.phone AS client_phone,
    c.city AS client_city,
    c.status AS client_status
FROM devices d
LEFT JOIN LATERAL (
    SELECT *
    FROM hardware_stats
    WHERE device_id = d.id
    ORDER BY timestamp DESC
    LIMIT 1
) hs ON true
LEFT JOIN clients c ON c.id = d.client_id;

-- ============================================
-- STEP 12: Record migration
-- ============================================

INSERT INTO schema_version (version, description)
VALUES ('1.4.0', 'Device live tracking: SUPERWATCH mode, device_events, device_screenshots, system_settings, settings_history, dynamic cleanup, fixed view')
ON CONFLICT (version) DO NOTHING;

-- ============================================
-- VERIFICATION QUERIES
-- Uncomment and run after migration to verify
-- ============================================

-- Check 1: New columns in devices
-- SELECT column_name, data_type FROM information_schema.columns
-- WHERE table_name = 'devices'
-- AND column_name IN ('client_id','tracking_mode','superwatch_reason','alert_count');

-- Check 2: New tables
-- SELECT table_name FROM information_schema.tables
-- WHERE table_name IN ('device_events','device_screenshots','system_settings','settings_history');

-- Check 3: Settings inserted correctly
-- SELECT category, COUNT(*) FROM system_settings GROUP BY category ORDER BY category;

-- Check 4: View works
-- SELECT id, serial_number, online_status, unresolved_alerts FROM device_live_status;

-- Check 5: Triggers exist
-- SELECT trigger_name, event_object_table FROM information_schema.triggers
-- WHERE trigger_name LIKE 'trigger_%';

-- ============================================
-- END OF MIGRATION #10
-- ============================================
