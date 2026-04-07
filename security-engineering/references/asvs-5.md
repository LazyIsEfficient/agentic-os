# ASVS 5.0 Key Requirements

## Level 1 (All Applications)
- Passwords minimum 12 characters
- Check against breached password lists
- Rate limiting on authentication
- Session tokens 128+ bits entropy
- HTTPS everywhere

## Level 2 (Sensitive Data)
- All L1 requirements plus MFA for sensitive operations
- Cryptographic key management
- Comprehensive security logging
- Input validation on all parameters

## Level 3 (Critical Systems)
- All L1/L2 plus hardware security modules for keys
- Threat modeling documentation
- Advanced monitoring and alerting
- Penetration testing validation
