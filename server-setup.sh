#!/bin/bash
# 在腾讯云服务器上执行一次，完成网站部署的所有前置配置
# 用法：bash server-setup.sh

set -e

echo "===== 1. 创建网站目录 ====="
mkdir -p /var/www/fusuhealth
echo "目录创建完成: /var/www/fusuhealth"

echo ""
echo "===== 2. 生成 SSH 部署密钥 ====="
ssh-keygen -t ed25519 -C "github-deploy" -f /root/.ssh/deploy_key -N ""
cat /root/.ssh/deploy_key.pub >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
echo "密钥生成完成"

echo ""
echo "===== 3. 写入 Nginx 网站配置 ====="
cat > /etc/nginx/sites-available/fusuhealth-web << 'NGINX_EOF'
server {
    listen 80;
    server_name fusuhealth.cn www.fusuhealth.cn;

    root /var/www/fusuhealth;
    index index.html;

    # Astro 静态站点路由
    location / {
        try_files $uri $uri/ $uri.html /index.html;
    }

    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # 安全头
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy strict-origin-when-cross-origin;

    # 禁止访问隐藏文件
    location ~ /\. { deny all; }

    access_log /var/log/nginx/fusuhealth-web.access.log;
    error_log  /var/log/nginx/fusuhealth-web.error.log;
}
NGINX_EOF

ln -sf /etc/nginx/sites-available/fusuhealth-web /etc/nginx/sites-enabled/
echo "Nginx 配置写入完成"

echo ""
echo "===== 4. 测试并重载 Nginx ====="
nginx -t && nginx -s reload
echo "Nginx 重载完成"

echo ""
echo "===== 5. 放一个临时占位页 ====="
cat > /var/www/fusuhealth/index.html << 'HTML_EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head><meta charset="UTF-8"><title>扶苏健康科技</title></head>
<body style="font-family:sans-serif;text-align:center;padding:100px;color:#333;">
  <h1>扶苏健康科技</h1>
  <p>网站正在部署中，GitHub Actions 完成后将自动更新...</p>
</body>
</html>
HTML_EOF
echo "占位页已放置"

echo ""
echo "================================================"
echo "✅ 服务器配置完成！"
echo ""
echo "下一步：将以下私钥复制到 GitHub Secrets"
echo "================================================"
echo ""
cat /root/.ssh/deploy_key
echo ""
echo "================================================"
echo "复制完整内容（从 -----BEGIN 到 -----END 那行）"
echo "================================================"
