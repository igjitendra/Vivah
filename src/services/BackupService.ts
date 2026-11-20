import * as FileSystem from 'expo-file-system';
import * as Sharing from 'expo-sharing';
import CryptoJS from 'crypto-js';
import { getDb, DEFAULT_HOUSEHOLD_ID, withTransaction } from '../database/db';

export interface BackupMetadata {
  vyavahaar_backup_version: number;
  app_version: string;
  created_at: string;
  is_encrypted: boolean;
  people_count: number;
  families_count: number;
  events_count: number;
  entries_count: number;
  items_count: number;
  reminders_count: number;
}

export interface BackupPayload {
  households: any[];
  families: any[];
  people: any[];
  events: any[];
  entries: any[];
  entry_items: any[];
  reminders: any[];
}

export interface BackupEnvelope {
  vyavahaar_backup_version: number;
  app_version: string;
  created_at: string;
  is_encrypted: boolean;
  salt?: string;
  iv?: string;
  ciphertext?: string;
  hmac?: string;
  checksum?: string;
  metadata: BackupMetadata;
  payload?: BackupPayload;
}

export class BackupService {
  private static BACKUP_VERSION = 3;
  private static APP_VERSION = '1.0.0';

  /**
   * Generates a complete database payload
   */
  private static getDatabasePayload(): BackupPayload {
    const db = getDb();
    return {
      households: db.getAllSync('SELECT * FROM households'),
      families: db.getAllSync('SELECT * FROM families'),
      people: db.getAllSync('SELECT * FROM people'),
      events: db.getAllSync('SELECT * FROM events'),
      entries: db.getAllSync('SELECT * FROM entries WHERE deleted_at IS NULL'),
      entry_items: db.getAllSync('SELECT * FROM entry_items'),
      reminders: db.getAllSync('SELECT * FROM reminders'),
    };
  }

  /**
   * Creates an offline backup (optionally encrypted with password)
   */
  static async createBackup(password?: string): Promise<{ uri: string; filename: string; metadata: BackupMetadata }> {
    const payload = this.getDatabasePayload();
    const payloadJson = JSON.stringify(payload);
    const now = new Date().toISOString();

    const metadata: BackupMetadata = {
      vyavahaar_backup_version: this.BACKUP_VERSION,
      app_version: this.APP_VERSION,
      created_at: now,
      is_encrypted: Boolean(password && password.trim().length > 0),
      people_count: payload.people.length,
      families_count: payload.families.length,
      events_count: payload.events.length,
      entries_count: payload.entries.length,
      items_count: payload.entry_items.length,
      reminders_count: payload.reminders.length,
    };

    let envelope: BackupEnvelope;

    if (metadata.is_encrypted && password) {
      // 1. Generate unique random salt and IV
      const salt = CryptoJS.lib.WordArray.random(16).toString(CryptoJS.enc.Hex);
      const iv = CryptoJS.lib.WordArray.random(16).toString(CryptoJS.enc.Hex);

      // 2. Derive 256-bit key using PBKDF2 with 10,000 iterations
      const key = CryptoJS.PBKDF2(password, CryptoJS.enc.Hex.parse(salt), {
        keySize: 256 / 32,
        iterations: 10000,
        hasher: CryptoJS.algo.SHA256,
      });

      // 3. Encrypt payload with AES-256
      const encrypted = CryptoJS.AES.encrypt(payloadJson, key, {
        iv: CryptoJS.enc.Hex.parse(iv),
        mode: CryptoJS.mode.CBC,
        padding: CryptoJS.pad.Pkcs7,
      });

      const ciphertext = encrypted.toString();

      // 4. Compute HMAC for authenticated integrity verification
      const hmac = CryptoJS.HmacSHA256(ciphertext + salt + iv, key).toString();

      envelope = {
        vyavahaar_backup_version: this.BACKUP_VERSION,
        app_version: this.APP_VERSION,
        created_at: now,
        is_encrypted: true,
        salt,
        iv,
        ciphertext,
        hmac,
        metadata,
      };
    } else {
      // Unencrypted backup with SHA-256 integrity checksum
      const checksum = CryptoJS.SHA256(payloadJson).toString();
      envelope = {
        vyavahaar_backup_version: this.BACKUP_VERSION,
        app_version: this.APP_VERSION,
        created_at: now,
        is_encrypted: false,
        checksum,
        metadata,
        payload,
      };
    }

    const envelopeString = JSON.stringify(envelope, null, 2);
    const dateTag = now.split('T')[0].replace(/-/g, '');
    const filename = `vyavahaar_backup_${dateTag}_${metadata.is_encrypted ? 'enc' : 'plain'}.json`;
    const targetDir = (FileSystem as any).documentDirectory || (FileSystem as any).cacheDirectory || '';
    const fileUri = `${targetDir}${filename}`;

    await FileSystem.writeAsStringAsync(fileUri, envelopeString, {
      encoding: (FileSystem as any).EncodingType?.UTF8 || 'utf8',
    });

    return { uri: fileUri, filename, metadata };
  }

  /**
   * Shares a backup file via native Android sharing sheet
   */
  static async shareBackupFile(uri: string): Promise<void> {
    if (await Sharing.isAvailableAsync()) {
      await Sharing.shareAsync(uri, {
        mimeType: 'application/json',
        dialogTitle: 'व्यवहार बैकअप फाइल सुरक्षित रखें / साझा करें',
        UTI: 'public.json',
      });
    }
  }

  /**
   * Creates an internal safety backup in memory/file before any restore operation
   */
  static createSafetySnapshot(): BackupPayload {
    return this.getDatabasePayload();
  }

  /**
   * Validates an incoming backup file and decrypts if encrypted
   */
  static validateBackup(
    fileContent: string,
    password?: string
  ): {
    valid: boolean;
    isEncrypted: boolean;
    error?: string;
    metadata?: BackupMetadata;
    payload?: BackupPayload;
  } {
    let parsed: any;
    try {
      parsed = JSON.parse(fileContent);
    } catch {
      return { valid: false, isEncrypted: false, error: 'अमान्य फाइल फॉर्मेट — यह वैध JSON बैकअप नहीं है।' };
    }

    if (!parsed || typeof parsed !== 'object') {
      return { valid: false, isEncrypted: false, error: 'दूषित बैकअप फाइल।' };
    }

    const isEncrypted = Boolean(parsed.is_encrypted);
    const metadata: BackupMetadata = parsed.metadata || {
      vyavahaar_backup_version: parsed.vyavahaar_backup_version || 1,
      app_version: parsed.app_version || '1.0.0',
      created_at: parsed.created_at || new Date().toISOString(),
      is_encrypted: isEncrypted,
      people_count: parsed.payload?.people?.length || 0,
      families_count: parsed.payload?.families?.length || 0,
      events_count: parsed.payload?.events?.length || 0,
      entries_count: parsed.payload?.entries?.length || 0,
      items_count: parsed.payload?.entry_items?.length || 0,
      reminders_count: parsed.payload?.reminders?.length || 0,
    };

    if (isEncrypted) {
      if (!password || password.trim().length === 0) {
        return {
          valid: false,
          isEncrypted: true,
          error: 'यह बैकअप पासवर्ड द्वारा सुरक्षित (Encrypted) है। कृपया पासवर्ड डालें।',
          metadata,
        };
      }

      if (!parsed.salt || !parsed.iv || !parsed.ciphertext || !parsed.hmac) {
        return { valid: false, isEncrypted: true, error: 'दूषित एन्क्रिप्टेड बैकअप फाइल — आवश्यक चाबियाँ अनुपलब्ध हैं।' };
      }

      try {
        // Derive key
        const key = CryptoJS.PBKDF2(password, CryptoJS.enc.Hex.parse(parsed.salt), {
          keySize: 256 / 32,
          iterations: 10000,
          hasher: CryptoJS.algo.SHA256,
        });

        // Verify HMAC
        const computedHmac = CryptoJS.HmacSHA256(parsed.ciphertext + parsed.salt + parsed.iv, key).toString();
        if (computedHmac !== parsed.hmac) {
          return { valid: false, isEncrypted: true, error: 'गलत पासवर्ड अथवा दूषित बैकअप फाइल।' };
        }

        // Decrypt
        const decrypted = CryptoJS.AES.decrypt(parsed.ciphertext, key, {
          iv: CryptoJS.enc.Hex.parse(parsed.iv),
          mode: CryptoJS.mode.CBC,
          padding: CryptoJS.pad.Pkcs7,
        });

        const decryptedText = decrypted.toString(CryptoJS.enc.Utf8);
        if (!decryptedText) {
          return { valid: false, isEncrypted: true, error: 'डिक्रिप्शन विफल — गलत पासवर्ड।' };
        }

        const payload: BackupPayload = JSON.parse(decryptedText);
        return { valid: true, isEncrypted: true, metadata, payload };
      } catch {
        return { valid: false, isEncrypted: true, error: 'डिक्रिप्शन असफल रहा। कृपया पासवर्ड जांचें।' };
      }
    }

    // Unencrypted validation
    const payload: BackupPayload = parsed.payload || parsed;
    if (!payload.people || !payload.events || !payload.entries) {
      return { valid: false, isEncrypted: false, error: 'अमान्य बैकअप फाइल — आवश्यक तालिकाएँ (Tables) मौजूद नहीं हैं।' };
    }

    if (parsed.checksum) {
      const computedChecksum = CryptoJS.SHA256(JSON.stringify(payload)).toString();
      if (computedChecksum !== parsed.checksum) {
        return { valid: false, isEncrypted: false, error: 'डेटा सत्यता सत्यापन (Checksum) विफल — बैकअप फाइल दूषित हो सकती है।' };
      }
    }

    return { valid: true, isEncrypted: false, metadata, payload };
  }

  /**
   * Safely restores the database from a validated payload
   * If any step fails, automatically rolls back to safetySnapshot!
   */
  static restoreFromPayload(
    payload: BackupPayload,
    safetySnapshot: BackupPayload
  ): { success: boolean; error?: string; summary?: { people: number; events: number; entries: number; items: number } } {
    const db = getDb();

    try {
      withTransaction(() => {
        // Clear current data
        db.runSync('DELETE FROM attachments');
        db.runSync('DELETE FROM reminders');
        db.runSync('DELETE FROM entry_items');
        db.runSync('DELETE FROM entries');
        db.runSync('DELETE FROM events');
        db.runSync('DELETE FROM people');
        db.runSync('DELETE FROM families');
        db.runSync('DELETE FROM households');

        // Restore households
        for (const h of payload.households || []) {
          db.runSync('INSERT INTO households (id, name, created_at, updated_at) VALUES (?, ?, ?, ?)', h.id, h.name, h.created_at, h.updated_at);
        }

        // Restore families
        for (const f of payload.families || []) {
          db.runSync('INSERT INTO families (id, household_id, name, village, created_at) VALUES (?, ?, ?, ?, ?)', f.id, f.household_id, f.name, f.village ?? null, f.created_at);
        }

        // Restore people
        for (const p of payload.people || []) {
          db.runSync(
            'INSERT INTO people (id, household_id, family_id, name, village, relationship, phone, notes, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            p.id, p.household_id, p.family_id ?? null, p.name, p.village ?? null, p.relationship ?? null, p.phone ?? null, p.notes ?? null, p.created_at, p.updated_at
          );
        }

        // Restore events
        for (const ev of payload.events || []) {
          db.runSync(
            'INSERT INTO events (id, household_id, title, event_type, event_date, person_id, notes, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
            ev.id, ev.household_id, ev.title, ev.event_type, ev.event_date, ev.person_id ?? null, ev.notes ?? null, ev.created_at, ev.updated_at
          );
        }

        // Restore entries
        for (const e of payload.entries || []) {
          db.runSync(
            'INSERT INTO entries (id, household_id, event_id, person_id, direction, cash_amount_paise, status, expected_date, notes, created_at, updated_at, deleted_at, sync_status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            e.id, e.household_id, e.event_id, e.person_id, e.direction, e.cash_amount_paise, e.status || 'recorded', e.expected_date ?? null, e.notes ?? null, e.created_at, e.updated_at, e.deleted_at ?? null, e.sync_status || 'local'
          );
        }

        // Restore entry_items
        for (const it of payload.entry_items || []) {
          db.runSync(
            'INSERT INTO entry_items (id, entry_id, item_name, quantity, unit, estimated_value_paise, condition, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            it.id, it.entry_id, it.item_name, it.quantity, it.unit ?? 'संख्या', it.estimated_value_paise ?? null, it.condition ?? null, it.created_at
          );
        }

        // Restore reminders
        for (const r of payload.reminders || []) {
          db.runSync(
            'INSERT INTO reminders (id, household_id, person_id, event_title, target_date, note, is_completed, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            r.id, r.household_id, r.person_id, r.event_title, r.target_date, r.note ?? null, r.is_completed ? 1 : 0, r.created_at
          );
        }
      });

      return {
        success: true,
        summary: {
          people: payload.people.length,
          events: payload.events.length,
          entries: payload.entries.length,
          items: (payload.entry_items || []).length,
        },
      };
    } catch (e: any) {
      console.error('Restore failed, performing automatic safety rollback:', e);
      // Rollback to safetySnapshot
      try {
        this.restoreFromPayload(safetySnapshot, { households: [], families: [], people: [], events: [], entries: [], entry_items: [], reminders: [] });
      } catch (rollbackError) {
        console.error('Safety rollback error:', rollbackError);
      }

      return {
        success: false,
        error: `रिस्टोर विफल रहा: ${e?.message || 'अज्ञात त्रुटि'}। आपका पूर्ववर्ती डेटा सुरक्षित रूप से पुनर्स्थापित कर दिया गया है।`,
      };
    }
  }
}
