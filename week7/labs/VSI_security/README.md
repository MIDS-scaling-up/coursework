1. Create two VSIs. One Ubuntu, one CentOS. Ensure you use a ssh key in the creation command. Perform the following steps on both nodes.
2. Edit /etc/ssh/sshd_config to prevent brute force attacks
    1. PermitRootLogin prohibit-password
    2. PasswordAuthentication no
3. Restart the ssh daemon (google is your friend here)
4. Ensure that you can only login with a ssh key and that password authentication is properly disabled
