#!/bin/bash

# Polymarket 文档部署脚本
# 使用方法: ./deploy.sh [mintlify|docker|nginx]

set -e

DEPLOY_TYPE=${1:-mintlify}

echo "🚀 Polymarket 文档部署脚本"
echo "============================"
echo ""

case $DEPLOY_TYPE in
  mintlify)
    echo "📦 部署到 Mintlify 官方托管..."
    echo ""
    echo "步骤："
    echo "1. 确保代码已推送到 GitHub"
    echo "2. 访问 https://dashboard.mintlify.com"
    echo "3. 连接你的 GitHub 仓库"
    echo "4. Mintlify 会自动检测并部署"
    echo ""
    echo "💡 提示: 这是最简单的部署方式！"

    read -p "是否现在推送到 GitHub? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      git add .
      read -p "输入提交信息: " commit_msg
      git commit -m "$commit_msg"
      git push origin main
      echo "✅ 代码已推送！现在去 Mintlify Dashboard 连接仓库吧。"
    fi
    ;;

  docker)
    echo "🐳 使用 Docker 部署..."
    echo ""

    # 检查 Docker 是否安装
    if ! command -v docker &> /dev/null; then
      echo "❌ Docker 未安装！"
      echo "请先安装 Docker: https://docs.docker.com/get-docker/"
      exit 1
    fi

    # 创建 Dockerfile
    cat > Dockerfile << 'EOF'
FROM node:18-alpine as builder
WORKDIR /app
RUN npm install -g mint
COPY . .
RUN mint build || echo "Mintlify build not available, using static serve"

FROM nginx:alpine
COPY . /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

    # 创建 nginx.conf
    cat > nginx.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

    # 创建 docker-compose.yml
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  polymarket-docs:
    build: .
    ports:
      - "3000:80"
    restart: unless-stopped
    container_name: polymarket-docs
EOF

    echo "✅ Docker 配置文件已创建"
    echo ""
    read -p "是否现在构建并启动? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      docker-compose build
      docker-compose up -d
      echo ""
      echo "✅ 部署完成！"
      echo "📱 访问: http://localhost:3000"
      echo ""
      echo "管理命令:"
      echo "  查看日志: docker-compose logs -f"
      echo "  停止服务: docker-compose down"
      echo "  重启服务: docker-compose restart"
    fi
    ;;

  nginx)
    echo "🔧 部署到 Nginx 服务器..."
    echo ""

    read -p "输入服务器地址 (例: user@your-server.com): " server_addr
    read -p "输入部署路径 (例: /var/www/polymarket-docs): " deploy_path
    read -p "输入域名 (例: docs.yourdomain.com): " domain_name

    echo ""
    echo "将要执行的操作:"
    echo "1. 上传文件到服务器: $server_addr:$deploy_path"
    echo "2. 配置 Nginx for: $domain_name"
    echo ""

    read -p "继续? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      # 上传文件
      echo "📤 上传文件..."
      rsync -avz --exclude 'node_modules' --exclude '.git' . "$server_addr:$deploy_path/"

      # 创建 Nginx 配置
      cat > /tmp/polymarket-docs-nginx.conf << EOF
server {
    listen 80;
    server_name $domain_name;
    root $deploy_path;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
}
EOF

      # 上传 Nginx 配置
      echo "📤 上传 Nginx 配置..."
      scp /tmp/polymarket-docs-nginx.conf "$server_addr:/tmp/"

      # 在服务器上执行配置命令
      ssh "$server_addr" << ENDSSH
        sudo mv /tmp/polymarket-docs-nginx.conf /etc/nginx/sites-available/polymarket-docs
        sudo ln -sf /etc/nginx/sites-available/polymarket-docs /etc/nginx/sites-enabled/
        sudo nginx -t && sudo systemctl reload nginx
ENDSSH

      echo ""
      echo "✅ 部署完成！"
      echo "📱 访问: http://$domain_name"
      echo ""
      echo "💡 配置 SSL 证书:"
      echo "ssh $server_addr"
      echo "sudo certbot --nginx -d $domain_name"
    fi
    ;;

  *)
    echo "❌ 未知的部署类型: $DEPLOY_TYPE"
    echo ""
    echo "使用方法:"
    echo "  ./deploy.sh mintlify  # 部署到 Mintlify 官方托管"
    echo "  ./deploy.sh docker    # 使用 Docker 部署"
    echo "  ./deploy.sh nginx     # 部署到 Nginx 服务器"
    exit 1
    ;;
esac

echo ""
echo "🎉 完成！"
