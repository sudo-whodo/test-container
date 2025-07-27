"""
HTTP Endpoint Tests
Simple HTTP status code checks for APIs running on private IP addresses.
Auto-detects server's private IP if no IPs specified in configuration.
"""

import pytest
import yaml
import os
import requests
import socket
import netifaces


def load_http_endpoint_config():
    """Load HTTP endpoint configuration from YAML file"""
    config_path = os.path.join(os.path.dirname(__file__), 'http_endpoint_config.yml')
    try:
        with open(config_path, 'r') as f:
            return yaml.safe_load(f)
    except FileNotFoundError:
        pytest.fail(f"HTTP endpoint config file not found: {config_path}")
    except yaml.YAMLError as e:
        pytest.fail(f"Error parsing HTTP endpoint config: {e}")


def get_private_ip_addresses():
    """Auto-detect private IP addresses of the current server"""
    private_ips = []

    try:
        # Get all network interfaces
        interfaces = netifaces.interfaces()

        for interface in interfaces:
            # Skip loopback interface
            if interface == 'lo' or interface.startswith('lo'):
                continue

            # Get IPv4 addresses for this interface
            addrs = netifaces.ifaddresses(interface)
            if netifaces.AF_INET in addrs:
                for addr_info in addrs[netifaces.AF_INET]:
                    ip = addr_info.get('addr')
                    if ip and is_private_ip(ip):
                        private_ips.append(ip)
    except Exception as e:
        print(f"Warning: Could not auto-detect private IPs using netifaces: {e}")

        # Fallback method using socket
        try:
            # Connect to a remote address to determine local IP
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            local_ip = s.getsockname()[0]
            s.close()

            if is_private_ip(local_ip):
                private_ips.append(local_ip)
            else:
                # If the detected IP is not private, add localhost as fallback
                private_ips.append("127.0.0.1")
        except Exception as fallback_e:
            print(f"Warning: Fallback IP detection failed: {fallback_e}")
            # Last resort - use localhost
            private_ips.append("127.0.0.1")

    # Remove duplicates while preserving order
    seen = set()
    unique_ips = []
    for ip in private_ips:
        if ip not in seen:
            seen.add(ip)
            unique_ips.append(ip)

    return unique_ips


def is_private_ip(ip):
    """Check if an IP address is in private ranges"""
    try:
        import ipaddress
        ip_obj = ipaddress.ip_address(ip)
        return ip_obj.is_private
    except:
        # Fallback manual check
        parts = ip.split('.')
        if len(parts) != 4:
            return False

        try:
            first = int(parts[0])
            second = int(parts[1])

            # 10.0.0.0/8
            if first == 10:
                return True
            # 172.16.0.0/12
            elif first == 172 and 16 <= second <= 31:
                return True
            # 192.168.0.0/16
            elif first == 192 and second == 168:
                return True
            # 127.0.0.0/8 (localhost)
            elif first == 127:
                return True

            return False
        except ValueError:
            return False


def get_ip_addresses_to_test(config):
    """Get list of IP addresses to test (from config or auto-detected)"""
    configured_ips = config.get('ip_addresses', [])

    # If IPs are configured and not empty, use them
    if configured_ips:
        print(f"Using configured IP addresses: {configured_ips}")
        return configured_ips

    # Otherwise, auto-detect private IPs
    auto_detected = get_private_ip_addresses()
    print(f"Auto-detected private IP addresses: {auto_detected}")
    return auto_detected


def generate_test_combinations():
    """Generate all combinations of IP addresses and endpoints"""
    config = load_http_endpoint_config()
    ip_addresses = get_ip_addresses_to_test(config)
    endpoints = config.get('endpoints', [])
    default_port = config.get('default_port', 8080)

    combinations = []
    for ip_address in ip_addresses:
        for endpoint in endpoints:
            # Create a descriptive test ID
            ip_short = ip_address.replace('.', '_')
            path_short = endpoint['path'].replace('/', '_').replace('-', '_')
            if path_short == '_':
                path_short = 'root'
            test_id = f"{ip_short}__{path_short}"

            combinations.append(pytest.param({
                'ip_address': ip_address,
                'port': default_port,
                'path': endpoint['path'],
                'description': endpoint['description'],
                'expected_status': endpoint.get('expected_status', 200),
                'required': endpoint.get('required', True)
            }, id=test_id))

    return combinations


class TestHTTPEndpoints:
    """Test HTTP endpoints on private IP addresses"""

    @pytest.fixture(scope="class")
    def http_config(self):
        """Load HTTP endpoint configuration"""
        return load_http_endpoint_config()

    def _test_http_endpoint(self, ip_address, port, path, description, expected_status, required, http_config):
        """Test a specific HTTP endpoint"""
        connection_config = http_config.get('connection_config', {})

        timeout = connection_config.get('timeout', 5)
        allow_redirects = connection_config.get('allow_redirects', True)
        max_redirects = connection_config.get('max_redirects', 3)
        custom_headers = connection_config.get('headers', {})

        print(f"\n🔍 Testing HTTP endpoint '{path}' ({description})")
        print(f"   IP: {ip_address}, Port: {port}")

        # Build URL
        url = f"http://{ip_address}:{port}{path}"

        headers = {
            **custom_headers
        }

        try:
            print(f"   URL: {url}")
            print(f"   Expected Status: {expected_status}")

            # Make the request
            response = requests.get(
                url,
                headers=headers,
                timeout=timeout,
                allow_redirects=allow_redirects,
                stream=False
            )

            print(f"   Actual Status: {response.status_code}")
            print(f"   Response Size: {len(response.content)} bytes")

            # Check status code
            if response.status_code != expected_status:
                error_msg = f"HTTP {response.status_code} (expected {expected_status}) for {path} on {ip_address}:{port}"
                print(f"❌ {error_msg}")
                if required:
                    assert False, error_msg
                else:
                    print(f"⚠️  Non-critical endpoint {path} failed")
                    return False, error_msg

            # Show response headers for debugging
            print(f"   Content-Type: {response.headers.get('Content-Type', 'Unknown')}")
            print(f"   Server: {response.headers.get('Server', 'Unknown')}")

            # Show first 100 characters of response for debugging
            if response.text:
                preview = response.text[:100].replace('\n', ' ').replace('\r', ' ')
                if len(response.text) > 100:
                    preview += "..."
                print(f"   Response Preview: {preview}")

            print(f"✅ HTTP {path} successful: HTTP {response.status_code}")
            return True, response.status_code

        except requests.exceptions.ConnectionError as e:
            error_msg = f"Connection error for {path} on {ip_address}:{port}: {str(e)}"
            print(f"❌ {error_msg}")
            if required:
                assert False, error_msg
            else:
                return False, error_msg

        except requests.exceptions.Timeout as e:
            error_msg = f"Timeout for {path} on {ip_address}:{port}: {str(e)}"
            print(f"❌ {error_msg}")
            if required:
                assert False, error_msg
            else:
                return False, error_msg

        except Exception as e:
            error_msg = f"Unexpected error for {path} on {ip_address}:{port}: {str(e)}"
            print(f"❌ {error_msg}")
            if required:
                assert False, error_msg
            else:
                return False, error_msg

    @pytest.mark.parametrize("test_combo", generate_test_combinations())
    def test_http_endpoints(self, http_config, test_combo):
        """Test HTTP endpoints for each IP/endpoint combination"""
        ip_address = test_combo['ip_address']
        port = test_combo['port']
        path = test_combo['path']
        description = test_combo['description']
        expected_status = test_combo['expected_status']
        required = test_combo['required']

        print(f"\n🌐 Testing HTTP Endpoint")
        print(f"   IP: {ip_address}")
        print(f"   Port: {port}")
        print(f"   Path: {path}")

        success, result = self._test_http_endpoint(
            ip_address, port, path, description,
            expected_status, required, http_config
        )

        if required:
            assert success, f"Required endpoint {path} failed for {ip_address}:{port}"
        elif not success:
            print(f"⚠️  Optional endpoint {path} failed for {ip_address}:{port}")

    def test_configuration_summary(self, http_config):
        """Display HTTP endpoint configuration summary"""
        configured_ips = http_config.get('ip_addresses', [])
        actual_ips = get_ip_addresses_to_test(http_config)
        endpoints = http_config.get('endpoints', [])
        default_port = http_config.get('default_port', 8080)
        connection_config = http_config.get('connection_config', {})

        print(f"\n📋 HTTP Endpoint Test Configuration Summary")

        if configured_ips:
            print(f"Configured IP addresses: {len(configured_ips)}")
            for ip in configured_ips:
                print(f"  - {ip}")
        else:
            print(f"Auto-detected private IP addresses: {len(actual_ips)}")
            for ip in actual_ips:
                print(f"  - {ip}")

        print(f"\nDefault Port: {default_port}")

        print(f"\nEndpoints to test: {len(endpoints)}")
        for endpoint in endpoints:
            required_str = "required" if endpoint.get('required', True) else "optional"
            print(f"  - {endpoint['path']} ({required_str}): {endpoint['description']}")

        print(f"\nConnection Configuration:")
        print(f"  - Timeout: {connection_config.get('timeout', 5)}s")
        print(f"  - Allow Redirects: {connection_config.get('allow_redirects', True)}")

        custom_headers = connection_config.get('headers', {})
        if custom_headers:
            print(f"\nCustom Headers:")
            for header, value in custom_headers.items():
                print(f"  - {header}: {value}")

        total_combinations = len(actual_ips) * len(endpoints)
        print(f"\nTotal test combinations: {total_combinations}")

        # Show example URLs that will be tested
        print(f"\nExample URLs that will be tested:")
        for ip in actual_ips[:2]:  # Show first 2 IPs as examples
            for endpoint in endpoints[:3]:  # Show first 3 endpoints as examples
                example_url = f"http://{ip}:{default_port}{endpoint['path']}"
                print(f"  - {example_url}")
            if len(endpoints) > 3:
                print(f"  - ... and {len(endpoints) - 3} more endpoints")
            if len(actual_ips) > 2:
                break
        if len(actual_ips) > 2:
            print(f"  - ... and {len(actual_ips) - 2} more IP addresses")
