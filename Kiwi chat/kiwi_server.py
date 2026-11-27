#!/usr/bin/env python3
"""
🥝 KiwiChat Custom Real-Time WebSocket Server
Pure Python 3 - Zero 3rd party dependencies! Uses standard library asyncio & sockets.

Works both LOCALLY (on your Mac) and on CLOUD HOSTS (like Render, Railway, Fly.io)!

Run locally:
    python3 kiwi_server.py

Run on Render / Cloud:
    Automatically binds to $PORT environment variable.
"""

import asyncio
import hashlib
import base64
import struct
import json
import time
import os

# Render and cloud hosts dynamically assign PORT through environment variables
PORT = int(os.environ.get("PORT", 8080))
MAGIC_WS_GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

# State Store
# clients: { userId: (reader, writer) }
clients = {}
# user_info: { userId: dict }
user_info = {}
# active_invite_codes: { code: { creatorUserId: ..., creatorInfo: ..., expiresAt: ... } }
active_invite_codes = {}

def get_masked_payload(data, mask):
    return bytes(b ^ mask[i % 4] for i, b in enumerate(data))

def make_ws_frame(message_str):
    """Encodes a text string into an RFC 6455 unmasked WebSocket frame."""
    payload = message_str.encode('utf-8')
    length = len(payload)
    frame = bytearray()
    frame.append(0x81) # FIN + text opcode
    
    if length <= 125:
        frame.append(length)
    elif length <= 65535:
        frame.append(126)
        frame.extend(struct.pack("!H", length))
    else:
        frame.append(127)
        frame.extend(struct.pack("!Q", length))
        
    frame.extend(payload)
    return bytes(frame)

async def send_json(writer, payload_dict):
    try:
        frame = make_ws_frame(json.dumps(payload_dict))
        writer.write(frame)
        await writer.drain()
    except Exception as e:
        print(f"⚠️ Error sending to client: {e}")

async def handle_handshake(reader, writer):
    request = b""
    while b"\r\n\r\n" not in request:
        chunk = await reader.read(1024)
        if not chunk:
            return False
        request += chunk
        
    headers = {}
    lines = request.decode('utf-8', errors='ignore').split("\r\n")
    for line in lines[1:]:
        if ": " in line:
            k, v = line.split(": ", 1)
            headers[k.lower()] = v.strip()
            
    sec_key = headers.get("sec-websocket-key")
    if not sec_key:
        # HTTP health check endpoint for Render / Railway / Cloud
        writer.write(b"HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 2\r\nConnection: close\r\n\r\nOK")
        await writer.drain()
        writer.close()
        return False
        
    # Calculate WebSocket Accept Hash
    sha1 = hashlib.sha1((sec_key + MAGIC_WS_GUID).encode('utf-8')).digest()
    accept_val = base64.b64encode(sha1).decode('utf-8')
    
    response = (
        "HTTP/1.1 101 Switching Protocols\r\n"
        "Upgrade: websocket\r\n"
        "Connection: Upgrade\r\n"
        f"Sec-WebSocket-Accept: {accept_val}\r\n\r\n"
    )
    writer.write(response.encode('utf-8'))
    await writer.drain()
    return True

async def read_ws_message(reader):
    """Reads and decodes an RFC 6455 client WebSocket frame."""
    header = await reader.read(2)
    if len(header) < 2:
        return None
        
    b1, b2 = header[0], header[1]
    opcode = b1 & 0x0F
    masked = (b2 & 0x80) != 0
    payload_len = b2 & 0x7F
    
    if opcode == 0x8: # Connection close
        return None
        
    if payload_len == 126:
        ext_len = await reader.read(2)
        payload_len = struct.unpack("!H", ext_len)[0]
    elif payload_len == 127:
        ext_len = await reader.read(8)
        payload_len = struct.unpack("!Q", ext_len)[0]
        
    mask = None
    if masked:
        mask = await reader.read(4)
        
    payload = await reader.read(payload_len)
    while len(payload) < payload_len:
        more = await reader.read(payload_len - len(payload))
        if not more:
            break
        payload += more
        
    if masked and mask:
        payload = get_masked_payload(payload, mask)
        
    if opcode == 0x9: # Ping -> send Pong
        return {"action": "ping"}
        
    try:
        return json.loads(payload.decode('utf-8'))
    except Exception:
        return None

async def dispatch_packet(packet, current_user_id, writer):
    action = packet.get("action")
    print(f"📦 [Packet Received]: {action} from user {current_user_id}")
    
    # 1. Register User / Heartbeat
    if action == "register_user":
        user_data = packet.get("user", {})
        uid = user_data.get("id")
        if uid:
            clients[uid] = writer
            user_info[uid] = user_data
            print(f"✅ User online: {user_data.get('displayName')} ({user_data.get('username')}) [Total Online: {len(clients)}]")
            await send_json(writer, {
                "action": "registered_success",
                "message": f"Connected to KiwiChat Server as {user_data.get('displayName')}"
            })
            
    # 2. Create 6-Digit Invite Code
    elif action == "create_invite_code":
        code = packet.get("code")
        creator = packet.get("creator", {})
        cid = creator.get("id")
        if code and cid:
            active_invite_codes[code] = {
                "code": code,
                "creator": creator,
                "expiresAt": time.time() + (15 * 60) # 15 minutes
            }
            print(f"🔑 New 6-digit code created: {code} by {creator.get('displayName')}")
            await send_json(writer, {
                "action": "invite_created",
                "code": code
            })
            
    # 3. Redeem 6-Digit Invite Code
    elif action == "redeem_invite_code":
        code = packet.get("code", "").replace(" ", "").replace("-", "")
        redeemer = packet.get("redeemer", {})
        redeemer_id = redeemer.get("id")
        
        invite = active_invite_codes.get(code)
        if not invite:
            await send_json(writer, {
                "action": "redeem_result",
                "success": False,
                "message": "Invalid or expired 6-digit code."
            })
            return
            
        if time.time() > invite["expiresAt"]:
            del active_invite_codes[code]
            await send_json(writer, {
                "action": "redeem_result",
                "success": False,
                "message": "This 6-digit code has expired."
            })
            return
            
        creator = invite["creator"]
        creator_id = creator.get("id")
        
        # Invalidate one-time code
        del active_invite_codes[code]
        print(f"🎉 Code {code} successfully paired: {creator.get('displayName')} <-> {redeemer.get('displayName')}")
        
        # Notify redeemer (Phone 2)
        await send_json(writer, {
            "action": "redeem_result",
            "success": True,
            "message": f"Connected with {creator.get('displayName')}!",
            "friend": creator
        })
        
        # Notify creator (Phone 1) if online
        if creator_id in clients:
            creator_writer = clients[creator_id]
            await send_json(creator_writer, {
                "action": "friend_paired_notification",
                "message": f"{redeemer.get('displayName')} connected using your code!",
                "friend": redeemer
            })
            
    # 4. Live Chat Message Transmission
    elif action == "send_message":
        message_data = packet.get("message", {})
        recipient_id = message_data.get("receiverId")
        sender_id = message_data.get("senderId")
        
        print(f"💬 Message from {sender_id} -> {recipient_id}: {message_data.get('textContent', '')[:30]}")
        
        # Forward immediately to recipient's socket if connected
        if recipient_id in clients:
            recipient_writer = clients[recipient_id]
            await send_json(recipient_writer, {
                "action": "incoming_message",
                "message": message_data
            })
        
        # Acknowledge sender
        await send_json(writer, {
            "action": "message_sent_ack",
            "messageId": message_data.get("id")
        })
        
    # 5. Call Signals (AudiText / KidTime Video)
    elif action in ["call_start", "call_end"]:
        friend_id = packet.get("friendId")
        if friend_id in clients:
            await send_json(clients[friend_id], packet)

async def client_handler(reader, writer):
    current_user_id = None
    try:
        ok = await handle_handshake(reader, writer)
        if not ok:
            return
            
        while True:
            packet = await read_ws_message(reader)
            if packet is None:
                break
            if packet.get("action") == "register_user":
                current_user_id = packet.get("user", {}).get("id")
            await dispatch_packet(packet, current_user_id, writer)
            
    except Exception as e:
        print(f"Client disconnected: {e}")
    finally:
        if current_user_id and current_user_id in clients:
            del clients[current_user_id]
            print(f"❌ User offline: {current_user_id} [Remaining: {len(clients)}]")
        writer.close()
        try:
            await writer.wait_closed()
        except Exception:
            pass

async def main():
    server = await asyncio.start_server(client_handler, "0.0.0.0", PORT)
    print("=" * 60)
    print("🥝  KiwiChat Custom Real-Time WebSocket Server")
    print(f"📡  Listening on port {PORT}")
    print(f"📲  Ready for local Wi-Fi and Cloud (Render/Railway) connections!")
    print("=" * 60)
    async with server:
        await server.serve_forever()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nServer stopped.")
