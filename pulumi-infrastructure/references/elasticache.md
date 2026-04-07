# ElastiCache Redis

```typescript
export const elasticacheCluster = new aws.elasticache.ReplicationGroup('ygg-redis', {
  replicationGroupDescription: 'YGG Redis cluster',
  nodeType: getInstanceSizing('redis').nodeType,
  port: 6379,
  parameterGroupName: 'default.redis7',
  numCacheClusters: isProduction ? 3 : 1,
  automaticFailoverEnabled: isProduction,
  multiAzEnabled: isProduction,
  atRestEncryptionEnabled: true,
  transitEncryptionEnabled: true,
  subnetGroupName: redisSubnetGroup.name,
  securityGroupIds: [redisSecurityGroup.id],
  tags: getTags({ Name: 'ygg-redis' }),
})
```

**Rules**:
- Always enable `atRestEncryptionEnabled` and `transitEncryptionEnabled`
- Production must have automatic failover and multi-AZ
- Skip ElastiCache in dev — use local Docker Redis
