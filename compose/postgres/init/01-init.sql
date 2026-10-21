-- PostgreSQL 初始化脚本，练习索引、执行计划、慢查询
CREATE TABLE IF NOT EXISTS orders (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT       NOT NULL,
    amount      NUMERIC(12,2) NOT NULL,
    status      TEXT         NOT NULL DEFAULT 'created',
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_orders_user_id  ON orders (user_id);
CREATE INDEX IF NOT EXISTS idx_orders_created  ON orders (created_at DESC);

-- 造一点数据，方便用 EXPLAIN ANALYZE 对比走索引和不走索引的差别
INSERT INTO orders (user_id, amount, status)
SELECT (random() * 10000)::BIGINT,
       (random() * 1000)::NUMERIC(12,2),
       (ARRAY['created','paid','shipped','done'])[1 + floor(random() * 4)]
FROM generate_series(1, 50000);

ANALYZE orders;
