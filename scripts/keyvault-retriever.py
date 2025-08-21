#!/usr/bin/env python3
"""
Azure Key Vault Secret Retriever
Swiss Re Infrastructure Challenge - Version 3
Author: Jesus Gracia
Date: 2025-08-21
"""

import os
import sys
import json
import logging
import requests
from datetime import datetime
from typing import Dict, Optional, Any

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/keyvault-retriever.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class KeyVaultRetriever:
    """
    Retrieves secrets from Azure Key Vault using Managed Identity.
    Designed for Ubuntu VMs with system-assigned managed identity.
    """
    
    def __init__(self, vault_name: str):
        """
        Initialize Key Vault retriever.
        
        Args:
            vault_name: Name of the Azure Key Vault
        """
        self.vault_name = vault_name
        self.vault_url = f"https://{vault_name}.vault.azure.net"
        self.api_version = "7.3"
        self.token = None
        self.token_expiry = None
        
        logger.info(f"Initialized KeyVaultRetriever for vault: {vault_name}")
        
    def get_access_token(self) -> str:
        """
        Get access token from Azure Instance Metadata Service (IMDS).
        
        Returns:
            Access token string
            
        Raises:
            Exception: If unable to obtain access token
        """
        try:
            # Check if token is still valid
            if self.token and self.token_expiry:
                if datetime.now().timestamp() < self.token_expiry:
                    logger.debug("Using cached access token")
                    return self.token
            
            # IMDS endpoint for managed identity
            url = "http://169.254.169.254/metadata/identity/oauth2/token"
            params = {
                'api-version': '2018-02-01',
                'resource': 'https://vault.azure.net'
            }
            headers = {'Metadata': 'true'}
            
            logger.info("Requesting access token from IMDS...")
            response = requests.get(url, params=params, headers=headers, timeout=10)
            response.raise_for_status()
            
            token_data = response.json()
            self.token = token_data['access_token']
            self.token_expiry = float(token_data['expires_on'])
            
            logger.info("Successfully obtained access token")
            return self.token
            
        except requests.exceptions.RequestException as e:
            logger.error(f"HTTP request failed: {str(e)}")
            raise
        except KeyError as e:
            logger.error(f"Invalid token response format: {str(e)}")
            raise
        except Exception as e:
            logger.error(f"Failed to get access token: {str(e)}")
            raise
            
    def get_secret(self, secret_name: str) -> str:
        """
        Retrieve a secret from Key Vault.
        
        Args:
            secret_name: Name of the secret to retrieve
            
        Returns:
            Secret value as string
            
        Raises:
            Exception: If unable to retrieve secret
        """
        try:
            # Ensure we have a valid token
            if not self.token:
                self.get_access_token()
                
            url = f"{self.vault_url}/secrets/{secret_name}"
            params = {'api-version': self.api_version}
            headers = {
                'Authorization': f'Bearer {self.token}',
                'Content-Type': 'application/json'
            }
            
            logger.info(f"Retrieving secret: {secret_name}")
            response = requests.get(url, params=params, headers=headers, timeout=10)
            
            if response.status_code == 401:
                # Token might be expired, try refreshing
                logger.info("Token expired, refreshing...")
                self.token = None
                self.get_access_token()
                headers['Authorization'] = f'Bearer {self.token}'
                response = requests.get(url, params=params, headers=headers, timeout=10)
            
            response.raise_for_status()
            
            secret_data = response.json()
            logger.info(f"Successfully retrieved secret: {secret_name}")
            return secret_data['value']
            
        except requests.exceptions.RequestException as e:
            logger.error(f"HTTP request failed for secret {secret_name}: {str(e)}")
            raise
        except KeyError as e:
            logger.error(f"Invalid secret response format: {str(e)}")
            raise
        except Exception as e:
            logger.error(f"Failed to retrieve secret {secret_name}: {str(e)}")
            raise
            
    def save_certificate(self, cert_name: str, cert_path: str, key_path: str) -> None:
        """
        Retrieve and save SSL certificate and private key.
        
        Args:
            cert_name: Name of the certificate secret in Key Vault
            cert_path: Path to save the certificate
            key_path: Path to save the private key
            
        Raises:
            Exception: If unable to save certificate
        """
        try:
            # Retrieve certificate bundle from Key Vault
            cert_bundle = self.get_secret(cert_name)
            
            # Parse the certificate bundle (assuming PEM format)
            if isinstance(cert_bundle, str):
                # If it's a JSON string, parse it
                if cert_bundle.startswith('{'):
                    cert_data = json.loads(cert_bundle)
                    certificate = cert_data.get('certificate', '')
                    private_key = cert_data.get('privateKey', '')
                else:
                    # Assume it's a concatenated PEM format
                    parts = cert_bundle.split('-----END CERTIFICATE-----')
                    if len(parts) >= 2:
                        certificate = parts[0] + '-----END CERTIFICATE-----'
                        private_key = parts[1].strip()
                    else:
                        certificate = cert_bundle
                        private_key = ''
            else:
                logger.error("Invalid certificate bundle format")
                raise ValueError("Certificate bundle must be a string")
            
            # Save certificate
            os.makedirs(os.path.dirname(cert_path), exist_ok=True)
            with open(cert_path, 'w') as f:
                f.write(certificate)
            os.chmod(cert_path, 0o644)
            logger.info(f"Certificate saved to {cert_path}")
            
            # Save private key if present
            if private_key:
                os.makedirs(os.path.dirname(key_path), exist_ok=True)
                with open(key_path, 'w') as f:
                    f.write(private_key)
                os.chmod(key_path, 0o600)
                logger.info(f"Private key saved to {key_path}")
            else:
                logger.warning("No private key found in certificate bundle")
                
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse certificate JSON: {str(e)}")
            raise
        except IOError as e:
            logger.error(f"Failed to write certificate files: {str(e)}")
            raise
        except Exception as e:
            logger.error(f"Failed to save certificate: {str(e)}")
            raise

    def get_all_secrets(self) -> Dict[str, str]:
        """
        Retrieve all secrets from Key Vault.
        
        Returns:
            Dictionary of secret names and values
        """
        secrets = {}
        try:
            # Get list of secrets
            if not self.token:
                self.get_access_token()
                
            url = f"{self.vault_url}/secrets"
            params = {'api-version': self.api_version}
            headers = {
                'Authorization': f'Bearer {self.token}',
                'Content-Type': 'application/json'
            }
            
            response = requests.get(url, params=params, headers=headers, timeout=10)
            response.raise_for_status()
            
            secrets_list = response.json().get('value', [])
            
            # Retrieve each secret
            for secret_info in secrets_list:
                secret_name = secret_info['id'].split('/')[-1]
                try:
                    secrets[secret_name] = self.get_secret(secret_name)
                except Exception as e:
                    logger.warning(f"Failed to retrieve secret {secret_name}: {str(e)}")
                    
            logger.info(f"Retrieved {len(secrets)} secrets from Key Vault")
            return secrets
            
        except Exception as e:
            logger.error(f"Failed to retrieve secrets list: {str(e)}")
            return secrets

def main():
    """
    Main execution function.
    """
    try:
        # Get configuration from environment
        vault_name = os.environ.get('KEY_VAULT_NAME')
        if not vault_name:
            # Try to determine from VM tags or use default
            vault_name = 'kv-swissre-prod'
            logger.warning(f"KEY_VAULT_NAME not set, using default: {vault_name}")
        
        # Initialize retriever
        retriever = KeyVaultRetriever(vault_name)
        
        # Retrieve and save SSL certificate
        try:
            retriever.save_certificate(
                cert_name='ssl-certificate',
                cert_path='/etc/ssl/certs/swissre.crt',
                key_path='/etc/ssl/private/swissre.key'
            )
            logger.info("SSL certificate retrieved and saved successfully")
        except Exception as e:
            logger.warning(f"Failed to retrieve SSL certificate: {str(e)}")
            # Continue execution even if certificate retrieval fails
        
        # Retrieve other secrets if needed
        try:
            # Example: Retrieve database connection string
            db_connection = retriever.get_secret('db-connection-string')
            if db_connection:
                # Save to environment file
                with open('/etc/environment.d/database.conf', 'w') as f:
                    f.write(f"DATABASE_URL={db_connection}\n")
                logger.info("Database connection string saved")
        except Exception:
            pass  # Optional secret, ignore if not present
        
        logger.info("Key Vault retrieval completed successfully")
        return 0
        
    except Exception as e:
        logger.error(f"Script execution failed: {str(e)}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
