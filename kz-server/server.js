/**
 * Сервер для хранения персональных данных в РК
 * Развернуть на: PS Cloud, Beeline Cloud, Yandex Cloud KZ
 * 
 * Требования:
 * - Node.js 18+
 * - PostgreSQL (рекомендуется) или MongoDB
 */

const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const crypto = require('crypto');

const app = express();
app.use(cors());
app.use(express.json());

// PostgreSQL подключение (сервер в РК)
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'anama_personal',
  user: process.env.DB_USER || 'anama',
  password: process.env.DB_PASSWORD || 'secure_password',
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

// Шифрование персональных данных
const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY || crypto.randomBytes(32);
const IV_LENGTH = 16;

function encrypt(text) {
  if (!text) return null;
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv('aes-256-cbc', ENCRYPTION_KEY, iv);
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return iv.toString('hex') + ':' + encrypted;
}

function decrypt(text) {
  if (!text) return null;
  const parts = text.split(':');
  const iv = Buffer.from(parts[0], 'hex');
  const encrypted = parts[1];
  const decipher = crypto.createDecipheriv('aes-256-cbc', ENCRYPTION_KEY, iv);
  let decrypted = decipher.update(encrypted, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
}

// Создание таблицы при старте
async function initDB() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS personal_data (
      id SERIAL PRIMARY KEY,
      visitor_id VARCHAR(20) UNIQUE NOT NULL,
      full_name_encrypted TEXT,
      email_encrypted TEXT,
      phone_encrypted TEXT,
      birth_date DATE,
      parent_full_name_encrypted TEXT,
      parent_phone_encrypted TEXT,
      is_anonymized BOOLEAN DEFAULT FALSE,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      deleted_at TIMESTAMP
    );
    
    CREATE TABLE IF NOT EXISTS audit_log (
      id SERIAL PRIMARY KEY,
      visitor_id VARCHAR(20),
      action VARCHAR(50) NOT NULL,
      details JSONB,
      ip_address VARCHAR(45),
      timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    CREATE INDEX IF NOT EXISTS idx_personal_visitor ON personal_data(visitor_id);
    CREATE INDEX IF NOT EXISTS idx_audit_visitor ON audit_log(visitor_id);
  `);
  console.log('✅ Database initialized');
}

// API: Сохранить персональные данные
app.post('/api/personal-data', async (req, res) => {
  try {
    const { visitorId, fullName, email, phone, birthDate, parentFullName, parentPhone } = req.body;
    
    await pool.query(`
      INSERT INTO personal_data (visitor_id, full_name_encrypted, email_encrypted, phone_encrypted, birth_date, parent_full_name_encrypted, parent_phone_encrypted)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      ON CONFLICT (visitor_id) 
      DO UPDATE SET 
        full_name_encrypted = $2,
        email_encrypted = $3,
        phone_encrypted = $4,
        birth_date = $5,
        parent_full_name_encrypted = $6,
        parent_phone_encrypted = $7,
        updated_at = CURRENT_TIMESTAMP
    `, [
      visitorId,
      encrypt(fullName),
      encrypt(email),
      encrypt(phone),
      birthDate,
      encrypt(parentFullName),
      encrypt(parentPhone)
    ]);
    
    // Аудит
    await pool.query(`
      INSERT INTO audit_log (visitor_id, action, ip_address)
      VALUES ($1, 'save_personal_data', $2)
    `, [visitorId, req.ip]);
    
    res.status(201).json({ success: true });
  } catch (error) {
    console.error('Error saving personal data:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// API: Получить персональные данные
app.get('/api/personal-data/:visitorId', async (req, res) => {
  try {
    const { visitorId } = req.params;
    
    const result = await pool.query(
      'SELECT * FROM personal_data WHERE visitor_id = $1 AND deleted_at IS NULL',
      [visitorId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Not found' });
    }
    
    const row = result.rows[0];
    
    // Аудит
    await pool.query(`
      INSERT INTO audit_log (visitor_id, action, ip_address)
      VALUES ($1, 'read_personal_data', $2)
    `, [visitorId, req.ip]);
    
    res.json({
      visitorId: row.visitor_id,
      fullName: decrypt(row.full_name_encrypted),
      email: decrypt(row.email_encrypted),
      phone: decrypt(row.phone_encrypted),
      birthDate: row.birth_date,
      parentFullName: decrypt(row.parent_full_name_encrypted),
      parentPhone: decrypt(row.parent_phone_encrypted),
      isAnonymized: row.is_anonymized,
    });
  } catch (error) {
    console.error('Error getting personal data:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// API: Удалить персональные данные (GDPR)
app.delete('/api/personal-data/:visitorId', async (req, res) => {
  try {
    const { visitorId } = req.params;
    
    // Мягкое удаление (для доказательства)
    await pool.query(`
      UPDATE personal_data 
      SET deleted_at = CURRENT_TIMESTAMP,
          full_name_encrypted = NULL,
          email_encrypted = NULL,
          phone_encrypted = NULL,
          parent_full_name_encrypted = NULL,
          parent_phone_encrypted = NULL
      WHERE visitor_id = $1
    `, [visitorId]);
    
    // Аудит
    await pool.query(`
      INSERT INTO audit_log (visitor_id, action, ip_address, details)
      VALUES ($1, 'delete_personal_data', $2, $3)
    `, [visitorId, req.ip, JSON.stringify({ gdpr_request: true })]);
    
    res.json({ success: true, message: 'Data deleted successfully' });
  } catch (error) {
    console.error('Error deleting personal data:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// API: Анонимизировать данные
app.patch('/api/personal-data/:visitorId/anonymize', async (req, res) => {
  try {
    const { visitorId } = req.params;
    
    await pool.query(`
      UPDATE personal_data 
      SET is_anonymized = TRUE,
          full_name_encrypted = NULL,
          email_encrypted = NULL,
          phone_encrypted = NULL,
          parent_full_name_encrypted = NULL,
          parent_phone_encrypted = NULL,
          updated_at = CURRENT_TIMESTAMP
      WHERE visitor_id = $1
    `, [visitorId]);
    
    // Аудит
    await pool.query(`
      INSERT INTO audit_log (visitor_id, action, ip_address)
      VALUES ($1, 'anonymize_data', $2)
    `, [visitorId, req.ip]);
    
    res.json({ success: true });
  } catch (error) {
    console.error('Error anonymizing data:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// API: Экспорт данных (GDPR право на переносимость)
app.get('/api/personal-data/:visitorId/export', async (req, res) => {
  try {
    const { visitorId } = req.params;
    
    const personalData = await pool.query(
      'SELECT * FROM personal_data WHERE visitor_id = $1',
      [visitorId]
    );
    
    const auditData = await pool.query(
      'SELECT action, timestamp FROM audit_log WHERE visitor_id = $1 ORDER BY timestamp DESC',
      [visitorId]
    );
    
    // Аудит
    await pool.query(`
      INSERT INTO audit_log (visitor_id, action, ip_address)
      VALUES ($1, 'export_data', $2)
    `, [visitorId, req.ip]);
    
    const row = personalData.rows[0] || {};
    
    res.json({
      personalData: {
        fullName: decrypt(row.full_name_encrypted),
        email: decrypt(row.email_encrypted),
        phone: decrypt(row.phone_encrypted),
        birthDate: row.birth_date,
        createdAt: row.created_at,
      },
      activityLog: auditData.rows,
      exportedAt: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Error exporting data:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', location: 'Kazakhstan' });
});

const PORT = process.env.PORT || 3001;

initDB().then(() => {
  app.listen(PORT, () => {
    console.log(`🇰🇿 KZ Personal Data Server running on port ${PORT}`);
    console.log(`📍 Data stored in Kazakhstan (compliance with Law "On Personal Data")`);
  });
});

