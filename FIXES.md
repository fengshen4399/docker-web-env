# 问题修复总结

## 🔧 已修复的问题

### 1. web.sh 脚本路径问题
**问题**: `./scripts/web.sh: line 126: ./manage.sh: No such file or directory`

**原因**: `web.sh` 脚本中部分函数使用了错误的路径 `./manage.sh` 而不是 `./scripts/manage.sh`

**修复**: 统一所有路径引用为 `./scripts/manage.sh`

**影响文件**:
- `scripts/web.sh` - 修复了 `restart_nginx()`, `restart_php()`, `reload_config()`, `rebuild_service()` 函数

### 2. 应用日志目录权限问题
**问题**: 应用无法写入 `/home/app/default/runtime` 目录

**原因**: 
- 目录权限设置不正确
- 容器内用户无法写入应用运行时目录

**修复**: 
- 移除了多余的单独挂载 `- /home/app/default/runtime:/www/runtime`
- 添加了权限修复功能
- 确保 `runtime` 目录及其子目录有正确的写权限

**影响文件**:
- `docker-compose.yml` - 移除多余挂载
- `scripts/manage.sh` - 添加 `fix-perms` 命令
- `install.sh` - 添加权限设置
- `deploy.sh` - 添加权限设置

## 🚀 新增功能

### 1. 权限修复命令
```bash
# 使用 web 命令
sudo web fix-perms

# 或直接使用 manage.sh
./scripts/manage.sh fix-perms
```

### 2. 快速修复脚本
```bash
./quick-fix.sh
```

## 📁 目录结构说明

```
/home/app/default/              # 应用根目录（挂载到容器 /www/）
├── index.php                   # 应用入口文件
├── health.php                  # 健康检查文件
└── runtime/                    # 运行时目录（应用日志、缓存等）
    ├── logs/                   # 应用日志
    ├── cache/                  # 缓存文件
    └── temp/                   # 临时文件
```

## 🔐 权限设置

- **应用目录**: `www-data:www-data` 权限 `755`
- **运行时目录**: `www-data:www-data` 权限 `777`（可写）

## ✅ 验证方法

### 1. 测试脚本路径
```bash
sudo web reload    # 应该正常工作
sudo web restart   # 应该正常工作
```

### 2. 测试权限
```bash
sudo web fix-perms # 修复权限
```

### 3. 测试应用日志写入
```bash
# 在容器内测试
docker compose exec web touch /www/runtime/logs/test.log
```

## 🎯 使用建议

1. **首次部署**: 运行 `./install.sh` 或 `./deploy.sh`
2. **权限问题**: 运行 `sudo web fix-perms`
3. **快速修复**: 运行 `./quick-fix.sh`
4. **日常管理**: 使用 `sudo web [command]` 命令

## 📝 注意事项

- `runtime` 目录已包含在应用挂载中，无需单独挂载
- 权限修复会设置 `runtime` 目录为 `777`，确保应用可写
- 所有脚本现在都有文件存在性检查，避免覆盖现有文件
