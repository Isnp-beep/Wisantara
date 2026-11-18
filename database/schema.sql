-- Wisantara - skema database MySQL (Laragon)
-- Jalankan: mysql -u root < database/schema.sql   (atau import lewat HeidiSQL/phpMyAdmin)
CREATE DATABASE IF NOT EXISTS wisantara CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE wisantara;

CREATE TABLE IF NOT EXISTS users (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(10) NOT NULL DEFAULT 'turis',
  language VARCHAR(5) NOT NULL DEFAULT 'id',
  avatar_url VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (email)
);

CREATE TABLE IF NOT EXISTS api_tokens (
  token CHAR(64) NOT NULL PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS destinations (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  region VARCHAR(120) NOT NULL,
  category VARCHAR(20) NOT NULL,
  price_idr INT UNSIGNED NOT NULL DEFAULT 0,
  lat DOUBLE NOT NULL,
  lng DOUBLE NOT NULL,
  image_url VARCHAR(255) NULL,
  image_credit VARCHAR(255) NULL,
  descriptions TEXT NOT NULL,      -- JSON {"id":"..","en":"..","zh":"..","ja":"..","ko":".."}
  access_times TEXT NOT NULL,      -- JSON {"Malang":{"car":150,"bike":135,"walk":45},...}
  access_notes TEXT NOT NULL,      -- JSON {"car":"..","bike":"..","walk":".."}
  pros TEXT NOT NULL,              -- JSON array
  cons TEXT NOT NULL,              -- JSON array
  equipment TEXT NOT NULL,         -- JSON array
  best_time VARCHAR(120) NULL,
  eat_nearby TEXT NOT NULL         -- JSON array [{"name":..,"note":..,"price":..}]
);

CREATE TABLE IF NOT EXISTS guides (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  region VARCHAR(120) NOT NULL,
  languages VARCHAR(120) NOT NULL,   -- contoh: id,en,zh
  price_idr INT UNSIGNED NOT NULL,
  bio VARCHAR(255) NULL,
  color VARCHAR(9) NOT NULL DEFAULT '#5C3A21'
);

CREATE TABLE IF NOT EXISTS bookings (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(16) NOT NULL,
  user_id INT UNSIGNED NOT NULL,
  destination_id INT UNSIGNED NOT NULL,
  guide_id INT UNSIGNED NULL,
  visit_date DATE NOT NULL,
  qty INT UNSIGNED NOT NULL DEFAULT 1,
  subtotal INT UNSIGNED NOT NULL,
  guide_fee INT UNSIGNED NOT NULL DEFAULT 0,
  service_fee INT UNSIGNED NOT NULL DEFAULT 0,
  total INT UNSIGNED NOT NULL,
  status VARCHAR(12) NOT NULL DEFAULT 'pending',   -- pending | paid | cancelled
  payment_method VARCHAR(20) NULL,
  payment_ref VARCHAR(40) NULL,
  paid_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (code),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (destination_id) REFERENCES destinations(id),
  FOREIGN KEY (guide_id) REFERENCES guides(id)
);

CREATE TABLE IF NOT EXISTS posts (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  destination_id INT UNSIGNED NOT NULL,
  guide_id INT UNSIGNED NULL,
  rating_place TINYINT UNSIGNED NOT NULL,
  rating_guide TINYINT UNSIGNED NULL,
  caption VARCHAR(500) NOT NULL DEFAULT '',
  image_url VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (destination_id) REFERENCES destinations(id),
  FOREIGN KEY (guide_id) REFERENCES guides(id)
);

CREATE TABLE IF NOT EXISTS post_likes (
  post_id INT UNSIGNED NOT NULL,
  user_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (post_id, user_id),
  FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS post_comments (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  post_id INT UNSIGNED NOT NULL,
  user_id INT UNSIGNED NOT NULL,
  body VARCHAR(300) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS follows (
  user_id INT UNSIGNED NOT NULL,
  follow_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (user_id, follow_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (follow_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS favorites (
  user_id INT UNSIGNED NOT NULL,
  destination_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (user_id, destination_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS plans (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  folder VARCHAR(40) NOT NULL DEFAULT 'Liburan',
  name VARCHAR(120) NOT NULL,
  start_date DATE NULL,
  end_date DATE NULL,
  budget_idr INT UNSIGNED NOT NULL DEFAULT 0,
  remind_depart TINYINT NOT NULL DEFAULT 1,
  remind_pack TINYINT NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS plan_items (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  plan_id INT UNSIGNED NOT NULL,
  day_no TINYINT UNSIGNED NOT NULL DEFAULT 1,
  time_label VARCHAR(8) NOT NULL DEFAULT '08.00',
  title VARCHAR(150) NOT NULL,
  note VARCHAR(255) NULL,
  kind VARCHAR(12) NOT NULL DEFAULT 'activity',   -- activity | food | ticket | guide | stay
  destination_id INT UNSIGNED NULL,
  booking_id INT UNSIGNED NULL,
  done TINYINT NOT NULL DEFAULT 0,
  FOREIGN KEY (plan_id) REFERENCES plans(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS plan_expenses (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  plan_id INT UNSIGNED NOT NULL,
  title VARCHAR(150) NOT NULL,
  amount INT UNSIGNED NOT NULL,
  booking_id INT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (plan_id) REFERENCES plans(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS packing_items (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  plan_id INT UNSIGNED NOT NULL,
  label VARCHAR(100) NOT NULL,
  done TINYINT NOT NULL DEFAULT 0,
  FOREIGN KEY (plan_id) REFERENCES plans(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS notifications (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  title VARCHAR(150) NOT NULL,
  body VARCHAR(255) NOT NULL,
  type VARCHAR(20) NOT NULL DEFAULT 'info',
  ref VARCHAR(60) NULL,                -- kunci unik agar pengingat tidak dobel
  is_read TINYINT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS phrases (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  lang VARCHAR(5) NOT NULL,
  src_id VARCHAR(120) NOT NULL,
  text_tr VARCHAR(200) NOT NULL
);
