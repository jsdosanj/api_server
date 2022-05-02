dscl localhost -create /Local/Default/Users/nagios
dscl localhost -create /Local/Default/Users/nagios UniqueID 999
dscl localhost -create /Local/Default/Users/nagios PrimaryGroupID 20
dscl localhost -create /Local/Default/Users/nagios NFSHomeDirectory /Users/nagios
dscl localhost -create /Local/Default/Users/nagios UserShell /bin/zsh
dscl localhost -create /Local/Default/Users/nagios RealName "nagios"


mkdir -p /Users/nagios/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA2hYT+X4TIRDiFGfXdkn3j+r23jspeHqxGnN1xnaBh5MlTzBmqIfgCLHxDCzgIDVKG0IXJFeSZPrvgitPFYv9heJ5wbgoZVIh7wIUxlgpjkVX3ldYCe/BaVbXxz950Y/noxZqZx8cvEJ8Kkjm36HwwOO7C0ItBvXSsnowr4dAMxScJ26nBT9HqHXI2DrNZHBIIsbGmFno997w25bo6FbhCPl5D0zUFN0TIABjAvebyCjachJ7Ll+dgcOdhkMXqD8al9iv5Qj5gAr/5ywNftEPaNGHRcjRuo2SQaTr42+RQ8gZa0Gxs4v8qGkcauHcG9OYLzXOBWncxwlVjs2/jb8Cgw== nagios@oversight.omnigroup.com" >> /Users/nagios/.ssh/authorized_keys
chown -R nagios:20 /Users/nagios
chmod -R g-w /Users/nagios
chmod 700 /Users/nagios/.ssh
