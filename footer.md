## Building / Contributing

### Install prerequisites

Golang 

```bash
wget https://dl.google.com/go/go1.15.6.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.15.6.linux-amd64.tar.gz
rm go1.15.6.linux-amd64.tar.gz
```

Terraform

```bash
LATEST_URL=$(curl https://releases.hashicorp.com/terraform/index.json | jq -r '.versions[].builds[].url | select(.|test("alpha|beta|rc")|not) | select(.|contains("linux_amd64"))' | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | tail -1)
curl ${LATEST_URL} > /tmp/terraform.zip
(cd /tmp && unzip /tmp/terraform.zip && chmod +x /tmp/terraform && sudo mv /tmp/terraform /usr/local/bin/)
```

### Run tests

Default tests will run through various validation steps then spin up an instance in k3s.
```bash
# assumes k3s config is located at ~/.kube/k3s_config, this is not the normal spot. Eitherut k3s config (/etc/racncher/k3s/k3s.yaml) and change ownership to the current user, or change `k8s_config` in test/k3s_fixture
make
```

To test the AWS backed version run.
```bash
make test_aws
```

> :warning: **Warning**: This will spin up CTFd in AWS which will cost you some money.
