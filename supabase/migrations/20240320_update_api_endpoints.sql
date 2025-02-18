ALTER TABLE api_endpoints
ADD COLUMN user_id uuid REFERENCES auth.users,
ADD COLUMN active boolean DEFAULT true;
