#!/bin/bash

# Update package list
sudo apt update

# Install Nginx Full
sudo apt install -y nginx

# Enable and start Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Install PHP-FPM with extensions for MySQL and PostgreSQL
sudo apt install -y php8.2-fpm php8.2-mysql php8.2-pgsql

# Enable and start PHP-FPM
sudo systemctl enable php8.2-fpm
sudo systemctl start php8.2-fpm

# Install PHP Composer globally
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === 'e21205b207c3ff031906575712edab6f13eb0b361f2085f1f1237b7126d785e826a450292b6cfd1d64d92e6563bbde02') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); exit(1); } echo PHP_EOL;"
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
php -r "unlink('composer-setup.php');"

# Install PostgreSQL 12
sudo apt install -y postgresql-12

# Enable and start PostgreSQL
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Configure PostgreSQL to listen on all addresses (0.0.0.0)
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/12/main/postgresql.conf

# Restart PostgreSQL to apply changes
sudo systemctl restart postgresql

# Login to PostgreSQL and create user 'user' with password 'Password'
sudo -u postgres psql -c "CREATE USER user WITH PASSWORD 'Password';"

# Add user entry to pg_hba.conf for specific IPs using md5 authentication
echo "host    all             user.name          0.0.0.0/24       md5" | sudo tee -a /etc/postgresql/12/main/pg_hba.conf

# Restart PostgreSQL to apply changes
sudo systemctl restart postgresql

# Configure Nginx to serve PHP files
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
sudo tee /etc/nginx/sites-available/default > /dev/null <<EOL
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.php index.html index.htm index.nginx-debian.html;

    server_name _;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL

# Restart Nginx to apply changes
sudo systemctl restart nginx

# Add the current user to the www-data group
sudo usermod -aG www-data $USER

# Optional: Display installed versions
nginx -v
php-fpm8.2 -v
psql --version
composer --version

echo "Installation and configuration completed successfully."
