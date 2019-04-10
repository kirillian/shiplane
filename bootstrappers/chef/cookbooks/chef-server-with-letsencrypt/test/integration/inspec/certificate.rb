describe x509_certificate("/etc/lego/certificates/#{ENV.fetch 'FQDN'}.crt") do
  its('validity_in_days') { should be > 30 }
  its('issuer.CN') { should eq "Let's Encrypt Authority X3" }
end
