-- Create offers table
CREATE TABLE IF NOT EXISTS offers (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    company VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO offers (title, description, price, company) VALUES
    ('Devops многоруков', 'НУЖНО ЗНАТЬ ВСЕ', 250000, 'Просто Devops');

-- Display confirmation
SELECT 'Database initialized successfully!' as message;
SELECT COUNT(*) as total_offers FROM offers;
