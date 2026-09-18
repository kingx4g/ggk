#!/usr/bin/env python3
"""
میسازه یک جفت کلید X25519 برای اینباند Reality.
اجرا: python3 scripts/generate-reality-keys.py
(نیاز به: pip install cryptography)
"""
from cryptography.hazmat.primitives.asymmetric.x25519 import X25519PrivateKey
from cryptography.hazmat.primitives import serialization
import base64
import os

priv = X25519PrivateKey.generate()
priv_bytes = priv.private_bytes(
    encoding=serialization.Encoding.Raw,
    format=serialization.PrivateFormat.Raw,
    encryption_algorithm=serialization.NoEncryption(),
)
pub_bytes = priv.public_key().public_bytes(
    encoding=serialization.Encoding.Raw, format=serialization.PublicFormat.Raw
)


def b64url(b):
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode()


print("Private Key (بذار توی inbounds/reality.json -> privateKey):")
print(" ", b64url(priv_bytes))
print()
print("Public Key (بده به کلاینت‌ها):")
print(" ", b64url(pub_bytes))
print()
print("Short ID (بذار توی inbounds/reality.json -> shortIds):")
print(" ", os.urandom(8).hex())
