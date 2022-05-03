#!/bin/bash
exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists curl; then
echo ''
else
  sudo apt update && sudo apt install curl -y < "/dev/null"
fi
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi
sleep 1 && curl -s https://raw.githubusercontent.com/cryptongithub/init/main/logo.sh | bash && sleep 1

sudo useradd -s /sbin/nologin geth
sudo rm -rf /home/geth
sudo mkdir -p /home/geth
sudo mkdir -p /home/geth/.ethereum/geth/
sudo chown -R geth:geth /home/geth
sudo chmod -R 700 /home/geth
if [ ! $PASS ]; then
read -p "Enter a new password for your account: " PASS
echo $PASS > /home/geth/.ethereum/password.txt
fi
echo -e '\n\e[42mInstall software\e[0m\n' && sleep 1
apt update && apt install unzip sudo -y < "/dev/null"
cd $HOME
wget -O geth-v1.0.0-alpha2-linux-amd64.zip https://github.com/oasysgames/oasys-validator/releases/download/v1.0.0-alpha2/geth-v1.0.0-alpha2-linux-amd64.zip
unzip geth-v1.0.0-alpha2-linux-amd64.zip
sudo mv geth /usr/local/bin/geth
wget -O genesis.zip https://github.com/oasysgames/oasys-validator/releases/download/v1.0.0-alpha2/genesis.zip
unzip genesis.zip
mv genesis/testnet.json /home/geth/genesis.json
sudo -u geth geth init /home/geth/genesis.json
echo '[ "enode://093c363d9fa759b58cb0a59d8ca664b4b4981873dc0305b113edf6d0c865089ed9894300b385e58bb3da2f7b8b575170522c5f542a9d47cbff7d28d3c8c8dd65@35.75.212.171:30303" ]' > /home/geth/.ethereum/geth/static-nodes.json

sudo -u geth geth account new --password "/home/geth/.ethereum/password.txt" >/home/geth/.ethereum/wallet.txt
OASYS_ADDRESS=$(grep -a "Public address of the key: " /home/geth/.ethereum/wallet.txt | sed -r 's/Public address of the key:   //')

# export NETWORK_ID=248
#export NETWORK_ID=9372
#export OASYS_ADDRESS="0xc3f3e1Fc51Fa86e4125712B4E838d8E910982503"
  
echo "[Unit]
Description=Oasys Node
After=network.target

[Service]
User=geth
Type=simple
ExecStart=$(which geth) \
 --networkid 9372 \
 --syncmode full --gcmode archive \
 --mine --miner.gaslimit 30000000 \
 --allow-insecure-unlock \
 --unlock $OASYS_ADDRESS \
 --password /home/geth/.ethereum/password.txt \
 --http --http.addr 0.0.0.0 --http.port 8545 \
 --http.vhosts '*' --http.corsdomain '*' \
 --http.api net,eth,web3 \
 --snapshot=false
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target" > $HOME/oasysd.service
sudo mv $HOME/oasysd.service /etc/systemd/system
sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable oasysd
sudo systemctl restart oasysd
