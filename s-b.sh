#!/bin/bash
apt update
apt install jq
curl -fsSL https://sing-box.app/install.sh | sh
cat > /etc/sing-box/config.json <<EOF
{
    "inbounds": [
        {
            "type": "vless",
            "listen": "::",
            "listen_port": 443,
            "users": [
                {
                    "uuid": "",
                    "flow": "xtls-rprx-vision"
                }
            ],
            "tls": {
                "enabled": true,
                "server_name": "www.hp.com",
                "reality": {
                    "enabled": true,
                    "handshake": {
                        "server": "www.hp.com",
                        "server_port": 443
                    },
                    "private_key": "",
                    "short_id": [
                        ""
                    ]
                }
            },
            "tag": "reality"
        }
    ],
    "outbounds": [
        {
            "type": "direct",
            "tag": "direct"
        }
    ],
    "route": {
        "rules": [
            {
                "inbound": [
                    "reality"
                ],
                "outbound": "direct"
            }
        ]
    }
}
EOF
UUID=$(sing-box generate uuid)    #生成uuid传入shell变量
echo "生成的uuid为:$UUID"
jq --arg UUID "$UUID" '.inbounds[0].users[0].uuid = $UUID' /etc/sing-box/config.json > temp.json && mv temp.json /etc/sing-box/config.json  #shell变量传入jq，修改uuid
KEYPAIR=$(sing-box generate reality-keypair)   #生成key
PRIVATE_KEY=$(echo "$KEYPAIR" | grep 'PrivateKey:' | awk '{print $2}')
PUBLIC_KEY=$(echo "$KEYPAIR" | grep 'PublicKey:' | awk '{print $2}')
jq --arg PRIVATE_KEY "$PRIVATE_KEY" '.inbounds[0].tls.reality.private_key = $PRIVATE_KEY' /etc/sing-box/config.json > temp.json && mv temp.json /etc/sing-box/config.json
echo "PUBLIC_KEY的值为:$PUBLIC_KEY" > /etc/sing-box/PUBLIC_KEY.txt

sudo systemctl enable sing-box
sudo systemctl restart sing-box 
KZSF=$(sysctl net.ipv4.tcp_congestion_control)
echo "当前拥塞控制算法$KZSF"

# 写入 TCP 拥塞控制算法 BBR
#echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf

# 写入默认队列调度算法 FQ
#echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
#sudo sysctl -p
