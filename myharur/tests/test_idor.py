import pytest
from uuid import uuid4
from fastapi import HTTPException
from app.db.idor import get_owned_resource

class MockResource:
    def __init__(self, resource_id, mmid):
        self.id = resource_id
        self.mmid = mmid

class MockSession:
    def __init__(self, resource):
        self.resource = resource
    async def get(self, model, resource_id):
        if str(resource_id) == str(self.resource.id):
            return self.resource
        return None

@pytest.mark.asyncio
async def test_idor_owner_allowed():
    owner_mmid = uuid4()
    res_id = uuid4()
    resource = MockResource(res_id, owner_mmid)
    session = MockSession(resource)
    
    result = await get_owned_resource(MockResource, res_id, owner_mmid, session)
    assert result.id == res_id

@pytest.mark.asyncio
async def test_idor_non_owner_denied():
    owner_mmid = uuid4()
    attacker_mmid = uuid4()
    res_id = uuid4()
    resource = MockResource(res_id, owner_mmid)
    session = MockSession(resource)
    
    with pytest.raises(HTTPException) as exc_info:
        await get_owned_resource(MockResource, res_id, attacker_mmid, session)
    
    assert exc_info.value.status_code == 403

@pytest.mark.asyncio
async def test_idor_not_found():
    owner_mmid = uuid4()
    res_id = uuid4()
    session = MockSession(MockResource(uuid4(), owner_mmid))
    
    with pytest.raises(HTTPException) as exc_info:
        await get_owned_resource(MockResource, res_id, owner_mmid, session)
    
    assert exc_info.value.status_code == 404
