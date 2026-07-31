import pytest
from app.crud.crud_user import validate_username, validate_display_name

def test_validate_username():
    # Valid
    assert validate_username("valid_name123") is None
    assert validate_username("john_doe") is None

    # Invalid characters/length
    assert validate_username("ab") is not None  # too short
    assert validate_username("a" * 31) is not None  # too long
    assert validate_username("invalid name") is not None  # spaces
    assert validate_username("invalid!name") is not None  # special characters
    assert validate_username("hello😀") is not None  # emoji
    assert validate_username("héllo") is not None  # unicode

    # Reserved words
    assert validate_username("system_admin") is not None
    assert validate_username("news_bot") is not None
    assert validate_username("police_chief") is not None
    
    # Abusive words
    assert validate_username("bad_shit") is not None

def test_validate_display_name():
    # Valid
    assert validate_display_name("John Doe") is None
    assert validate_display_name("A valid display name with spaces") is None
    
    # Invalid
    assert validate_display_name("") is not None
    assert validate_display_name("a" * 61) is not None
    assert validate_display_name("bad shit") is not None
