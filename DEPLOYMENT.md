# Polymarket 文档部署指南

本指南提供多种部署Polymarket文档的方案。

## 方案一：Mintlify 官方托管（推荐）

### 优势
- 最简单，零配置
- 自动构建和部署
- CDN加速，全球访问快
- 支持自定义域名
- 免费或付费计划

### 部署步骤

1. **推送代码到GitHub**
   ```bash
   git add .
   git commit -m "Add Polymarket documentation"
   git push origin main
   ```

2. **连接Mintlify**
   - 访问 [Mintlify Dashboard](https://dashboard.mintlify.com)
   - 创建账号或登录
   - 点击 "New Documentation"
   - 连接你的GitHub仓库
   - 选择这个项目

3. **自动部署**
   - Mintlify会自动检测 `docs.json`
   - 自动构建并部署
   - 获得一个 `*.mintlify.app` 域名

4. **自定义域名（可选）**
   - 在Dashboard中添加自定义域名
   - 配置DNS CNAME记录
   - 自动配置SSL证书

### 费用
- 免费计划：公开文档
- 付费计划：私有文档、更多自定义

---

## 方案二：部署到自己的服务器

Mintlify的渲染引擎不开源，但我们可以使用替代方案或导出静态站点。

### 选项 2A：使用 Docusaurus 替代

Docusaurus是Facebook开源的文档框架，功能类似。

#### 1. 安装Docusaurus

```bash
# 在项目同级目录创建新项目
npx create-docusaurus@latest polymarket-docs-static classic --typescript

cd polymarket-docs-static
```

#### 2. 迁移内容

将MDX文件迁移到Docusaurus的 `docs/` 目录：

```bash
# 复制文档文件
cp -r ../owaa-polymarket-docs/user-guide docs/
cp -r ../owaa-polymarket-docs/developers docs/
cp -r ../owaa-polymarket-docs/changelog docs/
```

#### 3. 配置 docusaurus.config.js

```javascript
module.exports = {
  title: 'Polymarket Documentation',
  tagline: 'The world\'s largest prediction market',
  url: 'https://your-domain.com',
  baseUrl: '/',

  themeConfig: {
    navbar: {
      title: 'Polymarket Docs',
      items: [
        {
          type: 'doc',
          docId: 'intro',
          position: 'left',
          label: 'User Guide',
        },
        {
          to: '/developers',
          label: 'Developers',
          position: 'left',
        },
      ],
    },
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
        },
      },
    ],
  ],
};
```

#### 4. 构建静态站点

```bash
npm run build
```

生成的静态文件在 `build/` 目录。

#### 5. 部署到服务器

使用Nginx部署：

```nginx
# /etc/nginx/sites-available/polymarket-docs
server {
    listen 80;
    server_name docs.yourdomain.com;

    root /var/www/polymarket-docs;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # 启用gzip压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml text/javascript;
}
```

```bash
# 复制构建文件到服务器
scp -r build/* user@your-server:/var/www/polymarket-docs/

# 重启Nginx
sudo systemctl restart nginx
```

---

### 选项 2B：使用 VitePress

VitePress是Vue团队开发的现代文档框架。

#### 1. 创建VitePress项目

```bash
npm init
npm add -D vitepress
```

#### 2. 创建配置文件

```javascript
// .vitepress/config.js
export default {
  title: 'Polymarket Documentation',
  description: 'Prediction market documentation',

  themeConfig: {
    nav: [
      { text: 'User Guide', link: '/user-guide/' },
      { text: 'Developers', link: '/developers/' },
      { text: 'Changelog', link: '/changelog/' }
    ],

    sidebar: {
      '/user-guide/': [
        {
          text: 'Get Started',
          items: [
            { text: 'What is Polymarket', link: '/user-guide/get-started/what-is-polymarket' },
            { text: 'How to Sign Up', link: '/user-guide/get-started/how-to-sign-up' },
          ]
        },
      ],
    }
  }
}
```

#### 3. 构建和部署

```bash
npm run docs:build

# 构建文件在 .vitepress/dist/
```

---

## 方案三：Docker 部署

### 使用 Docusaurus + Docker

#### 1. 创建 Dockerfile

```dockerfile
# Dockerfile
FROM node:18-alpine as builder

WORKDIR /app

# 复制package文件
COPY package*.json ./
RUN npm ci

# 复制源代码
COPY . .

# 构建
RUN npm run build

# 生产环境
FROM nginx:alpine

# 复制构建文件
COPY --from=builder /app/build /usr/share/nginx/html

# 复制Nginx配置
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

#### 2. 创建 nginx.conf

```nginx
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
```

#### 3. 创建 docker-compose.yml

```yaml
version: '3.8'

services:
  docs:
    build: .
    ports:
      - "3000:80"
    restart: unless-stopped
    environment:
      - NODE_ENV=production
```

#### 4. 构建和运行

```bash
# 构建镜像
docker-compose build

# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f
```

访问 `http://localhost:3000`

---

## 方案四：静态托管服务

### Vercel 部署

1. **安装Vercel CLI**
   ```bash
   npm i -g vercel
   ```

2. **部署**
   ```bash
   vercel
   ```

3. **配置 vercel.json**
   ```json
   {
     "buildCommand": "npm run build",
     "outputDirectory": "build",
     "framework": "docusaurus"
   }
   ```

### Netlify 部署

1. **安装Netlify CLI**
   ```bash
   npm i -g netlify-cli
   ```

2. **部署**
   ```bash
   netlify deploy --prod
   ```

3. **配置 netlify.toml**
   ```toml
   [build]
     command = "npm run build"
     publish = "build"

   [[redirects]]
     from = "/*"
     to = "/index.html"
     status = 200
   ```

---

## 方案五：使用 Mintlify CLI 本地构建

Mintlify CLI主要用于开发预览，但也可以尝试本地构建。

```bash
# 安装CLI
npm i -g mint

# 本地预览
mint dev

# 注意：Mintlify不提供直接导出静态HTML的功能
# 需要使用官方托管或切换到其他框架
```

---

## 推荐方案对比

| 方案 | 难度 | 成本 | 维护 | 性能 | 推荐度 |
|------|------|------|------|------|--------|
| Mintlify官方 | ⭐ | 免费/付费 | 零维护 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Docusaurus | ⭐⭐ | 免费 | 需自维护 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| VitePress | ⭐⭐ | 免费 | 需自维护 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Docker部署 | ⭐⭐⭐ | 服务器费用 | 需自维护 | ⭐⭐⭐ | ⭐⭐⭐ |
| Vercel/Netlify | ⭐⭐ | 免费/付费 | 自动化 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

---

## 快速开始建议

### 如果你想要最简单的方案：
**→ 使用 Mintlify 官方托管**

### 如果你想要完全控制：
**→ 使用 Docusaurus + Docker 部署到自己的服务器**

### 如果你想要免费且简单：
**→ 使用 Vercel 或 Netlify 部署**

---

## 服务器环境要求

如果选择自己服务器部署：

- **操作系统**: Ubuntu 20.04+ / CentOS 7+ / Debian 10+
- **内存**: 最低1GB，推荐2GB+
- **存储**: 最低500MB
- **软件**:
  - Node.js 18+
  - Nginx 或 Apache
  - Docker（如果使用容器）
  - PM2（Node.js进程管理）

---

## 域名和SSL配置

### 使用Let's Encrypt免费SSL

```bash
# 安装certbot
sudo apt install certbot python3-certbot-nginx

# 获取证书
sudo certbot --nginx -d docs.yourdomain.com

# 自动续期
sudo certbot renew --dry-run
```

---

## 监控和维护

### 使用PM2管理Node.js进程

```bash
# 安装PM2
npm install -g pm2

# 启动应用
pm2 start npm --name "docs" -- start

# 开机自启
pm2 startup
pm2 save

# 监控
pm2 monit
```

---

## 需要帮助？

根据你选择的部署方案，我可以帮你：
1. 生成完整的配置文件
2. 编写部署脚本
3. 迁移到其他文档框架
4. 配置CI/CD自动部署

请告诉我你想使用哪种方案！
