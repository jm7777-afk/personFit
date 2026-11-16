import { db } from '../config/database.js';

export class UserRepository {
  findByEmail(email) {
    return db.prepare('SELECT * FROM users WHERE email = ?').get(email);
  }

  findById(id) {
    return db.prepare('SELECT id, name, email, avatar, created_at FROM users WHERE id = ?').get(id);
  }

  create(data) {
    const stmt = db.prepare(`
      INSERT INTO users (name, email, password_hash, avatar)
      VALUES (@name, @email, @password_hash, @avatar)
    `);
    const result = stmt.run({
      name: data.name,
      email: data.email,
      password_hash: data.password_hash,
      avatar: data.avatar || null
    });
    return this.findById(result.lastInsertRowid);
  }

  update(id, data) {
    const current = db.prepare('SELECT * FROM users WHERE id = ?').get(id);
    if (!current) return null;

    const merged = { ...current, ...data };
    const stmt = db.prepare(`
      UPDATE users
      SET name = @name, avatar = @avatar, password_hash = @password_hash
      WHERE id = @id
    `);
    stmt.run({
      id,
      name: merged.name,
      avatar: merged.avatar,
      password_hash: merged.password_hash
    });
    return this.findById(id);
  }
}

export const userRepository = new UserRepository();
