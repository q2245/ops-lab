# CI/CD

```bash
make up PROFILE=cicd
```

访问 <http://localhost:3200>。

CI 的目的是「让每次提交都自动验证」，CD 的目的是「让发布可重复、可回滚」。

### 流水线阶段

1. lint
2. test
3. build
4. push
5. deploy

### 关键实践

- 镜像 tag 用 git commit hash，不要用 `latest`
- 回滚比发布更重要
- 配置与代码分离
