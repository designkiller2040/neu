"""Upload to YouTube (scheduled, private until publish time) via the official Data API."""
import pathlib

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

SCOPES = ["https://www.googleapis.com/auth/youtube.upload"]


def _service():
    token = pathlib.Path("token.json")
    creds = Credentials.from_authorized_user_file(token, SCOPES) if token.exists() else None
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            creds = InstalledAppFlow.from_client_secrets_file("client_secret.json", SCOPES).run_local_server(port=0)
        token.write_text(creds.to_json())
    return build("youtube", "v3", credentials=creds)


def upload(path: pathlib.Path, title: str, description: str, tags: list[str], publish_at_iso: str) -> str:
    body = {
        "snippet": {"title": title[:100], "description": description, "tags": tags, "categoryId": "15"},
        "status": {"privacyStatus": "private", "publishAt": publish_at_iso, "selfDeclaredMadeForKids": False},
    }
    req = _service().videos().insert(part="snippet,status", body=body,
                                     media_body=MediaFileUpload(str(path), chunksize=-1, resumable=True))
    resp = None
    while resp is None:
        _, resp = req.next_chunk()
    return resp["id"]
