CREATE TABLE IF NOT EXISTS gitlab_repository_tokens (
    repository_id INTEGER NOT NULL,
    -- TODO encrypt this
    access_token TEXT NOT NULL,
    token_type TEXT NOT NULL DEFAULT 'personal_access_token' CHECK (token_type IN ('group_access_token', 'personal_access_token', 'project_access_token')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    last_used_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(repository_id, vcs_provider),
    FOREIGN KEY (repository_id) REFERENCES repositories(id) ON DELETE CASCADE
);

CREATE INDEX idx_repository_tokens_repo_id ON repository_tokens(repository_id);
