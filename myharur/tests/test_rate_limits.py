import pytest
import time
from app.middleware.rate_limit import check_rate_limit

class MockPipeline:
    def __init__(self, counts):
        self.counts = counts
    def incr(self, key):
        pass
    def expire(self, key, ttl):
        pass
    async def execute(self):
        return [self.counts.get("val", 1)]

class MockRedis:
    def __init__(self, val=1):
        self.val = val
    def pipeline(self):
        return MockPipeline({"val": self.val})

@pytest.mark.asyncio
async def test_rate_limit_under_threshold():
    redis = MockRedis(val=5)
    allowed = await check_rate_limit(redis, "test_user", limit=10, window=60)
    assert allowed is True

@pytest.mark.asyncio
async def test_rate_limit_exceeded():
    redis = MockRedis(val=15)
    allowed = await check_rate_limit(redis, "test_user", limit=10, window=60)
    assert allowed is False
