# RDS PostgreSQL

```typescript
export const rdsInstance = new aws.rds.Instance('app-postgres', {
  engine: 'postgres',
  engineVersion: '15.4',
  instanceClass: getInstanceSizing('rds').instanceClass,
  allocatedStorage: getInstanceSizing('rds').allocatedStorage,
  maxAllocatedStorage: getInstanceSizing('rds').maxAllocatedStorage,
  dbName: appConfig.database.name,
  username: appConfig.database.username,
  manageMasterUserPassword: true,     // AWS-managed credential rotation
  storageEncrypted: true,
  multiAz: isProduction,
  backupRetentionPeriod: isProduction ? 7 : 1,
  skipFinalSnapshot: !isProduction,
  vpcSecurityGroupIds: [rdsSecurityGroup.id],
  dbSubnetGroupName: dbSubnetGroup.name,
  tags: getTags({ Name: 'app-postgres' }),
})

// Production: read replicas for horizontal scaling
if (isProduction) {
  for (let i = 0; i < 2; i++) {
    new aws.rds.Instance(`app-postgres-replica-${i}`, {
      replicateSourceDb: rdsInstance.identifier,
      instanceClass: getInstanceSizing('rds').instanceClass,
      storageEncrypted: true,
      tags: getTags({ Name: `app-postgres-replica-${i}` }),
    })
  }
}
```

**Rules**:
- Always use `manageMasterUserPassword: true` — never hardcode DB passwords
- Always enable `storageEncrypted`
- Production must have `multiAz: true` and read replicas
- Skip RDS in dev — use local Docker PostgreSQL
