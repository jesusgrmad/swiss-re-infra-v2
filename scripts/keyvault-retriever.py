#!/usr/bin/env python3
'''
Swiss Re Infrastructure Challenge - Key Vault Certificate Retriever
Author: Jesus Gracia
Date: August 18, 2025
Version: 3.0.0
Purpose: Retrieve SSL certificates from Azure Key Vault using Managed Identity
'''

import json
import logging
import os
import sys
import urllib.request
import urllib.error
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class KeyVaultRetriever:
    '''Azure Key Vault certificate retriever using Managed Identity'''
    
    def __init__(self, vault_name):
        self.vault_name = vault_name
        self.vault_url = f'https://{vault_name}.vault.azure.net'
        self.token = None
        logger.info(f'Initialized KeyVault retriever for {vault_name}')
    
    def get_access_token(self):
        '''Get access token from Instance Metadata Service'''
        try:
            # Instance Metadata Service URL
            url = 'http://169.254.169.254/metadata/identity/oauth2/token'
            params = {
                'api-version': '2018-02-01',
                'resource': 'https://vault.azure.net'
            }
            
            # Build request
            query_string = '&'.join([f'{k}={v}' for k, v in params.items()])
            request_url = f'{url}?{query_string}'
            
            req = urllib.request.Request(request_url)
            req.add_header('Metadata', 'true')
            
            # Execute request
            with urllib.request.urlopen(req, timeout=10) as response:
                data = json.loads(response.read().decode('utf-8'))
                self.token = data['access_token']
                logger.info('Successfully obtained access token')
                return True
                
        except Exception as e:
            logger.error(f'Failed to get access token: {e}')
            return False
    
    def get_certificate(self, cert_name):
        '''Retrieve certificate from Key Vault'''
        try:
            if not self.token:
                if not self.get_access_token():
                    return None
            
            # Build Key Vault URL
            url = f'{self.vault_url}/certificates/{cert_name}?api-version=7.3'
            
            req = urllib.request.Request(url)
            req.add_header('Authorization', f'Bearer {self.token}')
            
            with urllib.request.urlopen(req, timeout=10) as response:
                cert_data = json.loads(response.read().decode('utf-8'))
                logger.info(f'Successfully retrieved certificate {cert_name}')
                return cert_data
                
        except urllib.error.HTTPError as e:
            logger.error(f'HTTP error retrieving certificate: {e.code} {e.reason}')
        except Exception as e:
            logger.error(f'Error retrieving certificate: {e}')
        
        return None

def main():
    '''Main execution function'''
    logger.info('Swiss Re Key Vault Certificate Retriever')
    logger.info('Author: Jesus Gracia')
    logger.info(f'Started at {datetime.now()}')
    
    # Configuration from environment
    vault_name = os.environ.get('KEY_VAULT_NAME', 'kv-swissre-dev')
    cert_name = os.environ.get('CERTIFICATE_NAME', 'swissre-ssl')
    output_path = os.environ.get('CERT_OUTPUT_PATH', '/etc/ssl/certs/swissre.crt')
    
    logger.info(f'Configuration:')
    logger.info(f'  Vault: {vault_name}')
    logger.info(f'  Certificate: {cert_name}')
    logger.info(f'  Output: {output_path}')
    
    # Initialize retriever
    retriever = KeyVaultRetriever(vault_name)
    
    # Get certificate
    cert_data = retriever.get_certificate(cert_name)
    if not cert_data:
        logger.error('Failed to retrieve certificate')
        return 1
    
    logger.info('Certificate retrieval completed successfully')
    return 0

if __name__ == '__main__':
    sys.exit(main())