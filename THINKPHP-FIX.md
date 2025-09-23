# ThinkPHP 权限问题修复指南

## 🚨 问题描述

```
Sentry\Exception\FatalErrorException
Error: Uncaught think\exception\ErrorException: mkdir(): Permission denied in /www/vendor/topthink/framework/src/think/log/driver/File.php:70
```

## 🔍 问题分析

ThinkPHP 框架在尝试创建日志目录时遇到权限拒绝错误。这通常是因为：

1. **目录不存在**：ThinkPHP 需要的运行时目录结构不完整
2. **权限不足**：应用无法在运行时目录中创建子目录
3. **用户权限**：容器内的用户权限设置不正确

## ✅ 解决方案

### 方法1：使用专门的修复脚本（推荐）

```bash
# 运行 ThinkPHP 权限修复脚本
./scripts/fix-thinkphp-perms.sh
```

### 方法2：使用通用权限修复

```bash
# 使用 manage.sh 脚本
./scripts/manage.sh fix-perms

# 或使用 web 命令
sudo web fix-perms
```

### 方法3：手动修复

```bash
# 1. 进入容器
docker compose exec web bash

# 2. 创建完整的 ThinkPHP 目录结构
mkdir -p /www/runtime/log
mkdir -p /www/runtime/cache
mkdir -p /www/runtime/temp
mkdir -p /www/runtime/session
mkdir -p /www/runtime/compile
mkdir -p /www/runtime/logs

# 3. 设置权限
chmod -R 777 /www/runtime
chown -R www-data:www-data /www/runtime

# 4. 退出容器
exit
```

## 📁 ThinkPHP 目录结构

修复后的完整目录结构：

```
/www/runtime/                    # 运行时根目录
├── log/                        # ThinkPHP 日志目录
├── cache/                      # 缓存目录
├── temp/                       # 临时文件目录
├── session/                    # 会话目录
├── compile/                    # 编译目录
└── logs/                       # 通用日志目录
```

## 🔐 权限设置

- **所有者**：`www-data:www-data`
- **权限**：`777`（完全可读写）
- **递归设置**：所有子目录和文件

## 🧪 验证方法

### 1. 检查目录结构
```bash
docker compose exec web ls -la /www/runtime/
```

### 2. 测试写入权限
```bash
docker compose exec web touch /www/runtime/log/test.log
```

### 3. 测试 PHP 创建目录
```bash
docker compose exec web php -r "mkdir('/www/runtime/log/test_dir', 0777, true); echo '成功';"
```

## 🚀 预防措施

### 1. 在部署脚本中添加权限设置

在 `install.sh` 和 `deploy.sh` 中已经添加了权限设置：

```bash
# 创建 ThinkPHP 完整目录结构
mkdir -p /home/app/default/runtime/log
mkdir -p /home/app/default/runtime/cache
mkdir -p /home/app/default/runtime/temp
mkdir -p /home/app/default/runtime/session
mkdir -p /home/app/default/runtime/compile
mkdir -p /home/app/default/runtime/logs

# 设置权限
chown -R www-data:www-data /home/app/default/runtime
chmod -R 777 /home/app/default/runtime
```

### 2. 定期检查权限

```bash
# 定期运行权限检查
./scripts/manage.sh fix-perms
```

## 📝 注意事项

1. **安全性**：`777` 权限在生产环境中需要谨慎使用
2. **备份**：修复前建议备份重要数据
3. **监控**：定期检查日志目录的权限状态
4. **容器重启**：权限修复后可能需要重启容器

## 🆘 故障排除

如果问题仍然存在：

1. **检查容器状态**：
   ```bash
   docker compose ps
   ```

2. **检查用户权限**：
   ```bash
   docker compose exec web id www-data
   ```

3. **检查挂载点**：
   ```bash
   docker compose exec web mount | grep /www
   ```

4. **查看详细错误**：
   ```bash
   docker compose logs web
   ```

## ✅ 修复完成标志

当看到以下输出时，表示修复成功：

```
✓ /www/runtime/log 权限正常
✓ /www/runtime/cache 权限正常
✓ /www/runtime/temp 权限正常
✓ /www/runtime/session 权限正常
✓ /www/runtime/compile 权限正常
✓ /www/runtime/logs 权限正常
✅ ThinkPHP 权限修复完成！
```
