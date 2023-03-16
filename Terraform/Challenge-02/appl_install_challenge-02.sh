#!/usr/bin/env bash

## Artur Baruchi
## abaruchi@abaruchi.dev


## Variables
ChallengeDir="$HOME/ChallengeDevOps"


## Step 01 - Install everything
sudo apt-get update
sudo apt -y install software-properties-common
sudo add-apt-repository -y ppa:ondrej/php
sudo apt-get update
sudo apt -y install php7.4
sudo apt-get install -y php7.4-cli php7.4-json php7.4-common php7.4-mysql php7.4-zip php7.4-gd php7.4-mbstring php7.4-curl php7.4-xml php7.4-bcmath

#### Install Composer and Clone the Challenge DevOps Repository
cd $HOME || exit
git clone https://github.com/abaruchi/ChallengeDevOps.git

cd $ChallengeDir || exit
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php
php composer.phar -n update
php composer.phar -n install
