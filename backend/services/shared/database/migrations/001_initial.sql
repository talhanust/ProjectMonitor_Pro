-- Initial database setup
-- This file is for reference. Prisma will manage the actual migrations

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create custom types if needed
-- CREATE TYPE user_role AS ENUM ('USER', 'ADMIN', 'MANAGER');

-- Add any custom functions
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add any custom indexes or constraints not handled by Prisma
-- These will be applied after Prisma migrations
