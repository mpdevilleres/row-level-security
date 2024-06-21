import uuid
from typing import Annotated

from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel
from starlette import status
from sqlalchemy.orm import sessionmaker
from sqlalchemy import create_engine

fake_users_db = {
    "tenant-1": {
        "username": "tenant-1",
        "account_id": "d6a68ed7-7909-46de-97ec-e1dc8440ef60",
        "hashed_password": "fakehashedDemo@123456",
    },
    "tenant-2": {
        "username": "tenant-2",
        "account_id": "87670a1e-32c0-449c-af4e-ecb629c24fc9",
        "hashed_password": "fakehashedDemo@123456",
    },
    "tenant-3": {
        "username": "tenant-3",
        "account_id": "4add25a0-ec2d-4ee8-bcf2-7a4b2d557dd2",
        "hashed_password": "fakehashedDemo@123456",
    },
}


def fake_hash_password(password: str):
    return "fakehashed" + password


oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")


class User(BaseModel):
    username: str
    account_id: uuid.UUID


class UserInDB(User):
    hashed_password: str


def get_user(db, username: str):
    if username in db:
        user_dict = db[username]
        return UserInDB(**user_dict)


def fake_decode_token(token):
    # This doesn't provide any security at all
    # Check the next version
    user = get_user(fake_users_db, token)
    return user


async def get_current_user(token: Annotated[str, Depends(oauth2_scheme)]):
    user = fake_decode_token(token)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user


def get_account_session(
    current_user: Annotated[User, Depends(get_current_user)],
):
    engine = create_engine(f'postgresql+psycopg2://{current_user.account_id}@localhost:5432/postgres')
    return sessionmaker(engine)()


def get_session():
    engine = create_engine(f'postgresql+psycopg2://postgres@localhost:5432/postgres')
    return sessionmaker(engine)()
