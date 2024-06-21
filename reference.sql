CREATE SCHEMA backend;
ALTER SCHEMA backend OWNER TO postgres;

CREATE TABLE backend.account
(
  id    UUID DEFAULT gen_random_uuid() NOT NULL CONSTRAINT account_pkey PRIMARY KEY,
  name  VARCHAR                        NOT NULL
);

CREATE TABLE backend.fruit
(
  id UUID DEFAULT gen_random_uuid() NOT NULL CONSTRAINT fruit_pkey PRIMARY KEY,
  account_id UUID DEFAULT CURRENT_USER::UUID NULL CONSTRAINT fruit_clien_id_fkey REFERENCES backend.account,
  name VARCHAR NOT NULL,
  color VARCHAR NOT NULL,
  taste VARCHAR NOT NULL,
  size VARCHAR NOT NULL,
  quantity INTEGER NOT NULL
);

-- create a postgresql user based of the account table
CREATE OR REPLACE FUNCTION create_account_user()
  RETURNS TRIGGER AS
$$
BEGIN
  EXECUTE FORMAT('CREATE ROLE %I WITH LOGIN IN ROLE tenants', NEW.id);
  RETURN NEW;
END
$$
  LANGUAGE plpgsql;

-- create trigger to call create_account_user when a account is created
DROP TRIGGER IF EXISTS create_account_user_insert_account ON backend.account;
CREATE OR REPLACE TRIGGER create_account_user_insert_account
  AFTER INSERT
  ON backend.account
  FOR EACH ROW
EXECUTE PROCEDURE create_account_user();

-- delete a postgresql user based of the account table
CREATE OR REPLACE FUNCTION delete_account_user()
  RETURNS trigger AS
$$
BEGIN
  EXECUTE FORMAT('DROP ROLE IF EXISTS %I', OLD.id);
  RETURN OLD;
END
$$
  LANGUAGE plpgsql;

-- create trigger to call create_account_user when a account is created
DROP TRIGGER IF EXISTS delete_account_user_delete_account ON backend.account;
CREATE TRIGGER delete_account_user_delete_account
  BEFORE DELETE
  ON backend.account
  FOR EACH ROW
EXECUTE PROCEDURE delete_account_user();
-- ------------------------
-- END OF SCHEMA DEFINITION
-- ------------------------

CREATE ROLE tenants WITH LOGIN;
GRANT USAGE ON SCHEMA backend TO tenants;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA backend TO tenants;

CREATE POLICY tenancy_policy ON backend.fruit TO tenants USING (account_id::UUID = CURRENT_USER::UUID);
ALTER TABLE backend.fruit
  ENABLE ROW LEVEL SECURITY;

-- Fixtures
INSERT INTO backend.account (id, name)
VALUES ('d6a68ed7-7909-46de-97ec-e1dc8440ef60', 'tenant-1'),
       ('87670a1e-32c0-449c-af4e-ecb629c24fc9', 'tenant-2'),
       ('4add25a0-ec2d-4ee8-bcf2-7a4b2d557dd2', 'tenant-3');

INSERT INTO backend.fruit (account_id, name, color, taste, size, quantity)
VALUES ('d6a68ed7-7909-46de-97ec-e1dc8440ef60', 'apple', 'green', 'sour', 'M', 10),
       ('d6a68ed7-7909-46de-97ec-e1dc8440ef60', 'orange', 'orange', 'sweet', 'M', 20),
       ('d6a68ed7-7909-46de-97ec-e1dc8440ef60', 'banana', 'yellow', 'sweet', 'L', 15),
       ('87670a1e-32c0-449c-af4e-ecb629c24fc9', 'grape', 'purple', 'sweet', 'S', 10),
       ('87670a1e-32c0-449c-af4e-ecb629c24fc9', 'mango', 'green', 'sour', 'M', 30),
       ('87670a1e-32c0-449c-af4e-ecb629c24fc9', 'apple', 'red', 'sweet', 'M', 40),
       ('4add25a0-ec2d-4ee8-bcf2-7a4b2d557dd2', 'mango', 'yellow', 'sweet', 'L', 15),
       ('4add25a0-ec2d-4ee8-bcf2-7a4b2d557dd2', 'apple', 'green', 'sour', 'M', 15),
       ('4add25a0-ec2d-4ee8-bcf2-7a4b2d557dd2', 'orange', 'orange', 'sour', 'S', 15);

