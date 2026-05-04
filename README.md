📥 Installation
Clone the repository:

Bash
git clone [https://github.com/YourUsername/LAN_CHATAPP.git](https://github.com/Sorrow01001000/LAN_CHATAPP.git)
cd LAN_CHATAPP
Verify your dependencies: Make sure IUP, luasocket, and sqlite3 are properly linked to your Lua path.

Run the App:

Bash
lua Main.lua

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
🎮 How to Use
Launch & Login: Open the app and enter a nickname to log in.

Find Your IP: Navigate to the Profile tab. Give this IP address to the person you want to chat with.

Add a Contact: Go to the Contacts tab. Type your friend's name and their IP address, then click Save to Server List.

Connect: Click your friend's name in the saved list.

Chat: Click Connect & Chat to open the chat window and start sending messages!

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
🛠️ Troubleshooting
"I send a message, but nothing happens / Network Error."

Firewall Blocking: This is the #1 issue. Both computers must allow port 12345 through their Windows/System Firewall for Inbound/Outbound traffic. When Windows asks to allow lua.exe on public/private networks, click "Allow".

Wrong IP: Double-check that the "Target IP" in the chat screen matches your friend's current IP.

Same Network: Ensure both computers are connected to the same Wi-Fi or router subnet.

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
📂 Project Structure
Main.lua - The core GUI setup, screen routing, and user interaction logic.

network.lua - The TCP socket manager. Handles sending data and listening for incoming messages on Port 12345.

db_manager.lua - The SQLite interface. Manages the tables for messages and servers.

📜 License
This project is open-source and distributed under the MIT License. See the LICENSE file for more details.
