-- =============================================================================
-- Identifiants : UUID stockés en BINARY(16), générés par l'API (Fluent).
-- Dates : DATETIME(6) en UTC (heure de Paris − 1 h en hiver).
-- =============================================================================

-- Création de la base de données
DROP DATABASE IF EXISTS zakfit;
CREATE DATABASE zakfit CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Accès à la base de données
USE zakfit;

-- -----------------------------------------------------------------------------
-- Tables de référence (pré-remplies)
-- -----------------------------------------------------------------------------

-- Création de la table dietary_preferences
CREATE TABLE dietary_preferences (
    id BINARY(16) NOT NULL,
    name VARCHAR(30) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_dietary_preferences_name UNIQUE (name)
);

-- Création de la table food_categories (V2)
CREATE TABLE food_categories (
    id BINARY(16) NOT NULL,
    name VARCHAR(30) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_food_categories_name UNIQUE (name)
);

-- Création de la table activity_categories
CREATE TABLE activity_categories (
    id BINARY(16) NOT NULL,
    name VARCHAR(30) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_activity_categories_name UNIQUE (name)
);

-- Création de la table activity_types
CREATE TABLE activity_types (
    id BINARY(16) NOT NULL,
    name VARCHAR(50) NOT NULL,
    met_value DECIMAL(3,1) NULL,                       -- V2 : estimation des calories
    activity_category_id BINARY(16) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_activity_types_name UNIQUE (name),
    CONSTRAINT ck_activity_types_met_value CHECK (met_value IS NULL OR met_value BETWEEN 1.0 AND 25.0),
    CONSTRAINT fk_activity_types_activity_category_id FOREIGN KEY (activity_category_id)
        REFERENCES activity_categories (id) ON DELETE NO ACTION
);

-- -----------------------------------------------------------------------------
-- Utilisateurs
-- -----------------------------------------------------------------------------

-- Création de la table users
CREATE TABLE users (
    id BINARY(16) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(254) NOT NULL,
    password_hash VARCHAR(100) NOT NULL,
    birth_date DATE NULL,                              -- rempli à la complétion du profil
    sex ENUM('female', 'male') NULL,
    height_cm TINYINT UNSIGNED NULL,
    weight_kg DECIMAL(4,1) NULL,
    health_goal ENUM('lose_weight', 'maintain', 'gain_muscle') NULL,
    role ENUM('user', 'admin') NOT NULL DEFAULT 'user',          -- V2
    status ENUM('active', 'blocked') NOT NULL DEFAULT 'active',  -- V2
    created_at DATETIME(6) NULL,
    updated_at DATETIME(6) NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT ck_users_height_cm CHECK (height_cm IS NULL OR height_cm BETWEEN 100 AND 250),
    CONSTRAINT ck_users_weight_kg CHECK (weight_kg IS NULL OR weight_kg BETWEEN 30.0 AND 300.0)
);

-- Création de la table user_dietary_preferences (association n-n)
CREATE TABLE user_dietary_preferences (
    user_id BINARY(16) NOT NULL,
    dietary_preference_id BINARY(16) NOT NULL,
    PRIMARY KEY (user_id, dietary_preference_id),
    CONSTRAINT fk_user_dietary_preferences_user_id FOREIGN KEY (user_id)
        REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_user_dietary_preferences_dietary_preference_id FOREIGN KEY (dietary_preference_id)
        REFERENCES dietary_preferences (id) ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------
-- Nutrition
-- -----------------------------------------------------------------------------

-- Création de la table foods
-- user_id NULL = aliment de la base ; renseigné = aliment personnalisé de cet utilisateur
CREATE TABLE foods (
    id BINARY(16) NOT NULL,
    name VARCHAR(100) NOT NULL,
    kcal_per_100g DECIMAL(5,1) NOT NULL,
    protein_per_100g DECIMAL(4,1) NOT NULL,
    carbs_per_100g DECIMAL(4,1) NOT NULL,
    fat_per_100g DECIMAL(4,1) NOT NULL,
    portion_weight_g DECIMAL(5,1) NULL,
    created_at DATETIME(6) NULL,
    updated_at DATETIME(6) NULL,
    user_id BINARY(16) NULL,
    food_category_id BINARY(16) NULL,                  -- V2
    PRIMARY KEY (id),
    INDEX idx_foods_name (name),
    CONSTRAINT ck_foods_kcal CHECK (kcal_per_100g BETWEEN 0 AND 900),
    CONSTRAINT ck_foods_macros CHECK (protein_per_100g >= 0 AND carbs_per_100g >= 0 AND fat_per_100g >= 0
        AND protein_per_100g + carbs_per_100g + fat_per_100g <= 100),
    CONSTRAINT ck_foods_portion CHECK (portion_weight_g IS NULL OR portion_weight_g > 0),
    CONSTRAINT fk_foods_user_id FOREIGN KEY (user_id)
        REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_foods_food_category_id FOREIGN KEY (food_category_id)
        REFERENCES food_categories (id) ON DELETE SET NULL
);

-- Création de la table meals
CREATE TABLE meals (
    id BINARY(16) NOT NULL,
    type ENUM('breakfast', 'lunch', 'dinner', 'snack') NOT NULL,
    eaten_at DATETIME(6) NOT NULL,
    created_at DATETIME(6) NULL,
    updated_at DATETIME(6) NULL,
    user_id BINARY(16) NOT NULL,
    PRIMARY KEY (id),
    INDEX idx_meals_user_id_eaten_at (user_id, eaten_at),
    CONSTRAINT fk_meals_user_id FOREIGN KEY (user_id)
        REFERENCES users (id) ON DELETE CASCADE
);

-- Création de la table meal_foods (association n-n porteuse de la quantité)
CREATE TABLE meal_foods (
    meal_id BINARY(16) NOT NULL,
    food_id BINARY(16) NOT NULL,
    quantity DECIMAL(6,1) NOT NULL,
    quantity_unit ENUM('gram', 'unit') NOT NULL DEFAULT 'gram',
    PRIMARY KEY (meal_id, food_id),
    CONSTRAINT ck_meal_foods_quantity CHECK (quantity > 0),
    CONSTRAINT fk_meal_foods_meal_id FOREIGN KEY (meal_id)
        REFERENCES meals (id) ON DELETE CASCADE,
    CONSTRAINT fk_meal_foods_food_id FOREIGN KEY (food_id)
        REFERENCES foods (id) ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------
-- Activités physiques
-- -----------------------------------------------------------------------------

-- Création de la table activities
CREATE TABLE activities (
    id BINARY(16) NOT NULL,
    duration_min SMALLINT UNSIGNED NOT NULL,
    calories_burned SMALLINT UNSIGNED NULL,
    is_calories_estimated TINYINT(1) NOT NULL DEFAULT 0,   -- V2
    performed_at DATETIME(6) NOT NULL,
    created_at DATETIME(6) NULL,
    updated_at DATETIME(6) NULL,
    user_id BINARY(16) NOT NULL,
    activity_type_id BINARY(16) NOT NULL,
    PRIMARY KEY (id),
    INDEX idx_activities_user_id_performed_at (user_id, performed_at),
    CONSTRAINT ck_activities_duration_min CHECK (duration_min BETWEEN 1 AND 600),
    CONSTRAINT ck_activities_calories_burned CHECK (calories_burned IS NULL OR calories_burned <= 5000),
    CONSTRAINT fk_activities_user_id FOREIGN KEY (user_id)
        REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_activities_activity_type_id FOREIGN KEY (activity_type_id)
        REFERENCES activity_types (id) ON DELETE NO ACTION
);

-- -----------------------------------------------------------------------------
-- Objectifs
-- -----------------------------------------------------------------------------

-- Création de la table goals (un seul objectif par utilisateur)
CREATE TABLE goals (
    id BINARY(16) NOT NULL,
    calorie_mode ENUM('automatic', 'manual') NOT NULL DEFAULT 'automatic',
    activity_level ENUM('sedentary', 'light', 'moderate', 'very_active') NULL,
    daily_calories SMALLINT UNSIGNED NOT NULL,
    protein_g SMALLINT UNSIGNED NOT NULL,
    carbs_g SMALLINT UNSIGNED NOT NULL,
    fat_g SMALLINT UNSIGNED NOT NULL,
    weekly_sessions TINYINT UNSIGNED NOT NULL,
    weekly_calories_burned SMALLINT UNSIGNED NOT NULL,
    weekly_active_minutes SMALLINT UNSIGNED NOT NULL,
    target_weight_kg DECIMAL(4,1) NULL,                -- V2
    target_date DATE NULL,                             -- V2
    created_at DATETIME(6) NULL,
    updated_at DATETIME(6) NULL,
    user_id BINARY(16) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_goals_user_id UNIQUE (user_id),
    CONSTRAINT ck_goals_daily_calories CHECK (daily_calories BETWEEN 1000 AND 6000),
    CONSTRAINT ck_goals_weekly_sessions CHECK (weekly_sessions <= 14),
    CONSTRAINT ck_goals_activity_level CHECK (calorie_mode = 'manual' OR activity_level IS NOT NULL),
    CONSTRAINT ck_goals_target CHECK (target_weight_kg IS NULL OR target_date IS NOT NULL),
    CONSTRAINT fk_goals_user_id FOREIGN KEY (user_id)
        REFERENCES users (id) ON DELETE CASCADE
);

-- Création de la table goal_activity_categories (activités privilégiées, n-n)
CREATE TABLE goal_activity_categories (
    goal_id BINARY(16) NOT NULL,
    activity_category_id BINARY(16) NOT NULL,
    PRIMARY KEY (goal_id, activity_category_id),
    CONSTRAINT fk_goal_activity_categories_goal_id FOREIGN KEY (goal_id)
        REFERENCES goals (id) ON DELETE CASCADE,
    CONSTRAINT fk_goal_activity_categories_activity_category_id FOREIGN KEY (activity_category_id)
        REFERENCES activity_categories (id) ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------
-- Options (V2)
-- -----------------------------------------------------------------------------

-- Création de la table weight_entries (V2)
CREATE TABLE weight_entries (
    id BINARY(16) NOT NULL,
    weight_kg DECIMAL(4,1) NOT NULL,
    measured_on DATE NOT NULL,
    created_at DATETIME(6) NULL,
    user_id BINARY(16) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_weight_entries_user_id_measured_on UNIQUE (user_id, measured_on),
    CONSTRAINT ck_weight_entries_weight_kg CHECK (weight_kg BETWEEN 30.0 AND 300.0),
    CONSTRAINT fk_weight_entries_user_id FOREIGN KEY (user_id)
        REFERENCES users (id) ON DELETE CASCADE
);

-- Création de la table notification_settings (V2)
CREATE TABLE notification_settings (
    id BINARY(16) NOT NULL,
    meal_reminder TINYINT(1) NOT NULL DEFAULT 1,
    workout_reminder TINYINT(1) NOT NULL DEFAULT 1,
    weigh_in_reminder TINYINT(1) NOT NULL DEFAULT 0,
    motivation TINYINT(1) NOT NULL DEFAULT 1,
    summary_time TIME NOT NULL DEFAULT '18:00:00',
    updated_at DATETIME(6) NULL,
    user_id BINARY(16) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_notification_settings_user_id UNIQUE (user_id),
    CONSTRAINT fk_notification_settings_user_id FOREIGN KEY (user_id)
        REFERENCES users (id) ON DELETE CASCADE
);
