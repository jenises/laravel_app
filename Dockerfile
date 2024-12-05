# Usando a imagem oficial do php para apache com buster
FROM php:8.2-apache

USER root

# Instalação de tzdata
RUN apt-get update && apt-get install -y tzdata

# Configuração do fuso horário
RUN ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata

# Instalando extensões do PHP necessárias para o Laravel
RUN apt-get update && apt-get install -y \ 
    vim \ 
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    zip \
    libzip-dev \
    libpq-dev \
    apt-transport-https \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd \
    && docker-php-ext-install pdo pdo_pgsql zip

# Install Node.js from the default apt repository
RUN apt-get install -y nodejs \
    && apt-get install -y npm \
    && npm install -g npm@latest


# Habilitar o módulo de reescrita do Apache
RUN a2enmod rewrite

# Definindo o diretório de trabalho
WORKDIR /var/www/html

# Criar pastas storage e bootstrap/cache caso não existam
RUN mkdir -p /var/www/html/storage /var/www/html/bootstrap/cache

# Copie todos os arquivos do projeto Laravel para o contêiner
COPY . /var/www/html

# Dê permissões apropriadas para as pastas do Laravel
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
#dar permissão para o apache
RUN chown -R www-data:www-data /var/www/html

# Instale o Composer (gerenciador de dependências do PHP)
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copiar o arquivo de config do apache para não dar erro de permissão
COPY laravel-app.conf /etc/apache2/sites-available/laravel-app.conf

# Remove o arquivo de configuração padrão e habilita o laravel-app.confs
RUN a2dissite 000-default.conf && a2ensite laravel-app.conf

# Copiar o arquivo start.sh para o container
COPY start.sh /usr/local/bin/start.sh

# Dar permissão de execução para o script
RUN chmod +x /usr/local/bin/start.sh

# Exponha a porta 80
EXPOSE 80

# Executa o start.sh que foi copiados
CMD ["/usr/local/bin/start.sh"]