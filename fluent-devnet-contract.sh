#!/bin/bash

BOLD=$(tput bold)
RESET=$(tput sgr0)
YELLOW=$(tput setaf 3)

print_command() {
  echo -e "${BOLD}${YELLOW}$1${RESET}"
}

cd $HOME

print_command "Installing Cargo..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
. "$HOME/.cargo/env"

print_command "Installing NVM and Node..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"

if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
elif [ -s "/usr/local/share/nvm/nvm.sh" ]; then
    . "/usr/local/share/nvm/nvm.sh"
else
    echo "Error: nvm.sh not found!"
    exit 1
fi
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

print_command "Using Node version manager (nvm)..."
nvm install node
nvm use node

node -v
npm -v

print_command "Installing gblend tool..."
cargo install gblend

print_command "Running gblend..."
gblend

print_command "Installing dependencies..."
npm install

print_command "Installing dotenv package..."
npm install dotenv

print_command "Removing hardhat.config.js file..."
rm hardhat.config.js

print_command "Updating hardhat.config.js..."
cat <<EOF > hardhat.config.js
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-vyper");
require("dotenv").config();

module.exports = {
  defaultNetwork: "fluent_devnet1",
  networks: {
    fluent_devnet1: {
      url: 'https://rpc.dev.thefluent.xyz/',
      chainId: 20993,
      accounts: [\`0x\${process.env.DEPLOYER_PRIVATE_KEY}\`],
    },
  },
  solidity: {
    version: '0.8.19',
  },
  vyper: {
    version: "0.3.0",
  },
};
EOF

read -p "Enter your EVM wallet private key (without 0x): " WALLET_PRIVATE_KEY

print_command "Generating .env file..."
cat <<EOF > .env
DEPLOYER_PRIVATE_KEY=$WALLET_PRIVATE_KEY
EOF

print_command "Compiling smart contracts..."
npm run compile

print_command "Deploying smart contracts..."
npm run deploy
