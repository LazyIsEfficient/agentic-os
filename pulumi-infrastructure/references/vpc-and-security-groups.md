# VPC Networking and Security Groups

## VPC Networking

Use `@pulumi/awsx` for high-level VPC creation:

```typescript
import * as awsx from '@pulumi/awsx'

export const vpc = new awsx.ec2.Vpc(getResourceName('vpcName'), {
  cidrBlock: '10.0.0.0/16',
  numberOfAvailabilityZones: 2,
  enableDnsHostnames: true,
  enableDnsSupport: true,
  tags: getTags({ Name: getResourceName('vpcName') }),
})
```

Export VPC outputs for cross-module use:

```typescript
export const vpcId = vpc.vpcId
export const publicSubnetIds = vpc.publicSubnetIds
export const privateSubnetIds = vpc.privateSubnetIds
```

## Security Groups

Create per-service security groups scoped to the VPC CIDR:

```typescript
import * as aws from '@pulumi/aws'

// RDS — only allow PostgreSQL from within VPC
export const rdsSecurityGroup = new aws.ec2.SecurityGroup('rds-sg', {
  vpcId: vpc.vpcId,
  ingress: [{
    protocol: 'tcp',
    fromPort: 5432,
    toPort: 5432,
    cidrBlocks: [vpc.vpc.cidrBlock],
  }],
  tags: getTags({ Name: 'rds-sg' }),
})

// ElastiCache — only allow Redis from within VPC
export const redisSecurityGroup = new aws.ec2.SecurityGroup('redis-sg', {
  vpcId: vpc.vpcId,
  ingress: [{
    protocol: 'tcp',
    fromPort: 6379,
    toPort: 6379,
    cidrBlocks: [vpc.vpc.cidrBlock],
  }],
  tags: getTags({ Name: 'redis-sg' }),
})

// ECS — HTTP/HTTPS public, dynamic ports from VPC
export const ecsSecurityGroup = new aws.ec2.SecurityGroup('ecs-sg', {
  vpcId: vpc.vpcId,
  ingress: [
    { protocol: 'tcp', fromPort: 80, toPort: 80, cidrBlocks: ['0.0.0.0/0'] },
    { protocol: 'tcp', fromPort: 443, toPort: 443, cidrBlocks: ['0.0.0.0/0'] },
    { protocol: 'tcp', fromPort: 32768, toPort: 65535, cidrBlocks: [vpc.vpc.cidrBlock] },
  ],
  tags: getTags({ Name: 'ecs-sg' }),
})
```

**Rules**:
- Create security groups conditionally — dev skips RDS/ElastiCache SGs
- Never use `0.0.0.0/0` for database or cache ingress
- Use VPC CIDR for inter-service communication
