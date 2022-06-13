#!/bin/bash
echo $1 
PRIV=$1
echo $PRIV
dir=$PWD/$PRIV-ssl
create_ssl_cnf (){
cat > openssl.cnf << EOF
# OpenSSL root CA configuration file.
[ ca ]
default_ca = CA_default

[ CA_default ]
# Directory and file locations.
dir               = $dir
certs             = $dir/certs
crl_dir           = $dir/crl
new_certs_dir     = $dir/newcerts
database          = $dir/index.txt
serial            = $dir/serial
RANDFILE          = $dir/private/.rand

# The root key and root certificate.
private_key       = $dir/private/ca.key.pem
certificate       = $dir/certs/ca.cert.pem

# For certificate revocation lists.
crlnumber         = $dir/crlnumber
crl               = $dir/crl/ca.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

# SHA-1 is deprecated, so use SHA-2 instead.
default_md        = sha256

name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = no
policy            = policy_strict

[ policy_strict ]
# The root CA should only sign intermediate certificates that match.
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ policy_loose ]
# Allow the intermediate CA to sign a more diverse range of certificates.
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
default_bits        = 2048
distinguished_name  = req_distinguished_name
string_mask         = utf8only

# SHA-1 is deprecated, so use SHA-2 instead.
default_md          = sha256

# Extension to add when the -x509 option is used.
x509_extensions     = v3_ca

[ req_distinguished_name ]
# See <https://en.wikipedia.org/wiki/Certificate_signing_request>.
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

# Optionally, specify some defaults.
countryName_default             = GB
stateOrProvinceName_default     = England
localityName_default            =
0.organizationName_default      = Alice Ltd
organizationalUnitName_default  =
emailAddress_default            =

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ usr_cert ]
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection

[ server_cert ]
basicConstraints = CA:TRUE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
# extendedKeyUsage = serverAuth

[ crl_ext ]
authorityKeyIdentifier=keyid:always

[ ocsp ]
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature
extendedKeyUsage = critical,OCSPSigning
EOF

}

create_certificate()
{
# https://jamielinux.com/docs/openssl-certificate-authority/create-the-root-pair.html

    mkdir $PRIV-ssl
    cd $PRIV-ssl
    mkdir  csr certs newcerts private 
    echo 1000 > serial
    touch index.txt   
    
    openssl genrsa -out private/ca.key.pem 4096
    
    openssl req -config ../openssl.cnf \
	    -key private/ca.key.pem \
	    -new -x509 -days 7300 -sha256 -extensions v3_ca \
	    -out certs/ca.cert.pem \
	    -subj "/C=US/ST=Massachusetts/L=Boston/O=Oracle/CN=NetworkFirewall/"
    cd ..
    openssl genrsa -out $PRIV-ssl/private/$PRIV.key.pem 2048

    # Start by generating a certificate.  This will be used as the FWD proxy
    # secret on the firewall.
    openssl req -config openssl.cnf \
	    -key $PRIV-ssl/private/$PRIV.key.pem \
	    -new -sha256 -out $PRIV-ssl/csr/$PRIV.fwd.csr.pem \
	    -subj "/C=US/ST=Massachusetts/L=Boston/O=Oracle/CN=$PRIV.fwd/"
    
    openssl ca -batch -config openssl.cnf \
	    -extensions v3_intermediate_ca -days 375 -notext -md sha256 \
	    -in $PRIV-ssl/csr/$PRIV.fwd.csr.pem \
	    -out $PRIV-ssl/certs/$PRIV.fwd.cert.pem \
	    -subj "/C=US/ST=Massachusetts/L=Boston/O=Oracle/CN=$PRIV.fwd/"


    # next generate the server certificate.  The server cert will be installed on the trusted
    # server and used in the inbound inspection secret on the firewall

    # this is being signed usign the same root (ca.cert.pem) that was used to sign the
    # fwd secret. But we could just have also used a different root all together
    openssl req -config openssl.cnf \
	    -key $PRIV-ssl/private/$PRIV.key.pem \
	    -new -sha256 -out $PRIV-ssl/csr/$PRIV.inb.csr.pem \
	    -subj "/C=US/ST=Massachusetts/L=Boston/O=Oracle/CN=$PRIV.inb/"
    
    openssl ca -batch -config openssl.cnf \
	    -extensions server_cert -days 375 -notext -md sha256 \
	    -in $PRIV-ssl/csr/$PRIV.inb.csr.pem \
	    -out $PRIV-ssl/certs/$PRIV.inb.cert.pem \
	    -subj "/C=US/ST=Massachusetts/L=Boston/O=Oracle/CN=$PRIV/"
    
    cat > $PRIV-ssl/$PRIV.ssl-forward-proxy.json << EOF
{
  "caCertOrderedList" : [
    "$(perl -pe 's/\n/\\n/' $PRIV-ssl/certs/ca.cert.pem)"
  ],
  "certKeyPair": {
    "cert" : "$(perl -pe 's/\n/\\n/' $PRIV-ssl/certs/$PRIV.fwd.cert.pem)",
    "key":   "$(perl -pe 's/\n/\\n/' $PRIV-ssl/private/$PRIV.key.pem)" 
  }
}
EOF

cat > $PRIV-ssl/$PRIV.ssl-inbound-inspection.json << EOF
{
  "caCertOrderedList" : [
    "$(perl -pe 's/\n/\\n/' $PRIV-ssl/certs/ca.cert.pem)"
  ],
  "certKeyPair": {
    "cert" : "$(perl -pe 's/\n/\\n/' $PRIV-ssl/certs/$PRIV.inb.cert.pem)",
    "key":   "$(perl -pe 's/\n/\\n/' $PRIV-ssl/private/$PRIV.key.pem)" 
  }
}
EOF
    
    cat $PRIV-ssl/certs/ca.cert.pem $PRIV-ssl/certs/$PRIV.inb.cert.pem $PRIV-ssl/certs/$PRIV.fwd.cert.pem > $PRIV-ssl/certs/$PRIV.bundle.pem

    
    openssl verify -CAfile $PRIV-ssl/certs/ca.cert.pem $PRIV-ssl/certs/$PRIV.inb.cert.pem
    openssl verify -CAfile $PRIV-ssl/certs/ca.cert.pem $PRIV-ssl/certs/$PRIV.fwd.cert.pem
    

cd ..
}
# Check if IP/DNS name is provided for the certificate and error out if not 
if [ -z "$PRIV" ]; then
    echo "Please provide IP address or DNS Name for the certificate" 
    exit 2;
# Validate that certificate doesnt exist for this IP/DNS name 
elif [[ -f $PRIV-ssl/private/$PRIV.key.pem ]]; then
echo "Certificate exists for this IP/DNS Name"
ls -l $PRIV-ssl/certs/$PRIV.fwd.cert.pem
ls -l $PRIV-ssl/certs/$PRIV.inb.cert.pem
exit 1;
# Create Certificate workflow
else 
create_ssl_cnf
create_certificate
fi
