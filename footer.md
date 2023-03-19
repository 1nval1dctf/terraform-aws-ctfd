## Building / Contributing

### Install prerequisites

#### Golang

```bash
wget https://dl.google.com/go/go1.19.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.19.5.linux-amd64.tar.gz
rm go1.19.5.linux-amd64.tar.gz
```

#### Terraform

```bash
LATEST_URL=$(curl https://releases.hashicorp.com/terraform/index.json | jq -r '.versions[].builds[].url | select(.|test("alpha|beta|rc")|not) | select(.|contains("linux_amd64"))' | sort -t. -k 1,1n -k 2,2n -k 3,3n | tail -1)
curl ${LATEST_URL} > /tmp/terraform.zip
(cd /tmp && unzip /tmp/terraform.zip && chmod +x /tmp/terraform && sudo mv /tmp/terraform /usr/local/bin/)

```


#### Pre-commit and tools


Follow: https://github.com/antonbabenko/pre-commit-terraform#how-to-install

### Run tests

Default tests will run through various validation steps then spin up an instance with docker.
```bash
make
```

To test the AWS backed version run.
```bash
make test_aws
```

> :warning: **Warning**: This will spin up CTFd in AWS which will cost you some money.
