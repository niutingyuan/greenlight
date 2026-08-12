CREATE TABLE IF NOT EXISTS permissions(
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    code text NOT NULL
);

CREATE TABLE IF NOT EXISTS users_permissions(
    user_id bigint NOT NULL REFERENCES users ON DELETE CASCADE,
    permission_id bigint NOT NULL REFERENCES permissions ON DELETE CASCADE,
    PRIMARY KEY(user_id,permission_id)
);

INSERT INTO permissions (code)
VALUES
    ('movies:read'),
    ('movies:write');