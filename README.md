# Wine Docker 容器 (支持RDP)

基于 `scottyhardy/docker-wine:latest` 构建的 Wine 容器,优化运行环境.

## 快速启动


```bash
# 启动容器并设置密码
docker run -d \
  --name Wine \
  -p 3389:3389 \
  -v "/Docker/wine/Desktop:/home/wineuser/Desktop" \
  -v "/Docker/wine/exe:/home/wineuser/exe" \
  yht0511/wine-rdp
docker exec -it Wine passwd wineuser
```