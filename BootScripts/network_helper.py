#!/usr/bin/env python3
"""
Network Helper - Ensures network connectivity or graceful offline mode
Prompts for WiFi if needed, or continues offline
"""

import subprocess
import time
import sys

class NetworkHelper:
    def __init__(self):
        self.connected = False
        self.offline_mode = False
    
    def check_connection(self):
        """Check if internet is available"""
        try:
            result = subprocess.run(['ping', '-c', '1', '-W', '2', '8.8.8.8'],
                                  capture_output=True, timeout=3)
            return result.returncode == 0
        except:
            return False
    
    def get_wifi_networks(self):
        """Scan for available WiFi networks"""
        try:
            result = subprocess.run(['nmcli', 'device', 'wifi', 'list'],
                                  capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')[1:]  # Skip header
                networks = []
                for line in lines:
                    if line.strip():
                        # Parse network name (SSID)
                        parts = line.split()
                        if len(parts) >= 2:
                            ssid = parts[1] if parts[0] == '*' else parts[0]
                            networks.append(ssid)
                return networks
        except:
            pass
        return []
    
    def connect_wifi(self, ssid, password):
        """Connect to WiFi network"""
        try:
            print(f"   Connecting to {ssid}...")
            result = subprocess.run(['nmcli', 'device', 'wifi', 'connect', ssid, 
                                   'password', password],
                                  capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                print("   ✅ Connected!")
                time.sleep(2)
                return self.check_connection()
            else:
                print(f"   ❌ Failed: {result.stderr}")
                return False
        except Exception as e:
            print(f"   ❌ Error: {e}")
            return False
    
    def prompt_wifi_connection(self):
        """Prompt user to connect to WiFi"""
        print("\n" + "="*60)
        print("📡 WiFi Connection")
        print("="*60)
        
        print("\n🔍 Scanning for networks...")
        networks = self.get_wifi_networks()
        
        if not networks:
            print("❌ No WiFi networks found")
            return False
        
        print(f"\n📶 Found {len(networks)} networks:")
        for i, network in enumerate(networks[:10], 1):
            print(f"   {i}. {network}")
        
        if len(networks) > 10:
            print(f"   ... and {len(networks)-10} more")
        
        try:
            print("\n" + "-"*60)
            choice = input("Select network (1-{}), 'other', or 'skip': ".format(min(len(networks), 10)))
            
            if choice.lower() == 'skip':
                return False
            
            if choice.lower() == 'other':
                ssid = input("Enter network name (SSID): ").strip()
            else:
                idx = int(choice) - 1
                if 0 <= idx < len(networks):
                    ssid = networks[idx]
                else:
                    print("Invalid choice")
                    return False
            
            password = input(f"Enter password for '{ssid}': ").strip()
            
            return self.connect_wifi(ssid, password)
            
        except (ValueError, KeyboardInterrupt):
            print("\n❌ Cancelled")
            return False
    
    def ensure_connection(self, allow_prompt=True):
        """Ensure network connection or enable offline mode"""
        print("\n" + "="*60)
        print("🌐 Network Status Check")
        print("="*60)
        
        # Check if already connected
        print("\n🔍 Checking internet connection...")
        if self.check_connection():
            print("✅ Internet connected!")
            self.connected = True
            return True
        
        print("⚠️  No internet connection detected")
        
        # Check if ethernet is plugged in
        try:
            result = subprocess.run(['ip', 'link', 'show'], 
                                  capture_output=True, text=True, timeout=2)
            if 'state UP' in result.stdout and 'eth' in result.stdout:
                print("⚠️  Ethernet appears connected but no internet")
                print("   (May need DHCP time or cable issue)")
                time.sleep(3)
                if self.check_connection():
                    print("✅ Internet now available!")
                    self.connected = True
                    return True
        except:
            pass
        
        # Try WiFi prompt if allowed
        if allow_prompt:
            print("\n💡 Options:")
            print("   1. Connect to WiFi now")
            print("   2. Continue offline (use archive only)")
            print("   3. Exit to shell")
            
            try:
                choice = input("\nSelect option (1-3): ").strip()
                
                if choice == '1':
                    if self.prompt_wifi_connection():
                        self.connected = True
                        return True
                    else:
                        print("\n⚠️  WiFi connection failed")
                        return self.enable_offline_mode()
                
                elif choice == '2':
                    return self.enable_offline_mode()
                
                elif choice == '3':
                    print("\n🐚 Dropping to shell...")
                    print("   Run 'exit' to return to wrapper")
                    subprocess.run(['bash'])
                    return self.ensure_connection(allow_prompt=False)
                
                else:
                    print("Invalid choice, continuing offline...")
                    return self.enable_offline_mode()
                    
            except KeyboardInterrupt:
                print("\n\n⚠️  Interrupted")
                return self.enable_offline_mode()
        
        return self.enable_offline_mode()
    
    def enable_offline_mode(self):
        """Enable offline mode with archive only"""
        print("\n" + "="*60)
        print("📦 OFFLINE MODE ENABLED")
        print("="*60)
        print("\n✅ Will use driver archive only")
        print("⚠️  Some drivers may be missing for exotic hardware")
        print("💡 Archive covers 90%+ of common hardware")
        
        self.offline_mode = True
        self.connected = False
        
        input("\nPress Enter to continue...")
        return False

def main():
    """Test network helper"""
    helper = NetworkHelper()
    helper.ensure_connection()
    
    if helper.connected:
        print("\n✅ Internet available - can download drivers!")
    else:
        print("\n📦 Offline mode - using archive only")

if __name__ == "__main__":
    main()
