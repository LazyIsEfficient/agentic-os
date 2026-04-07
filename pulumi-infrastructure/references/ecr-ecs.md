# ECR and ECS

## ECR Container Registry

```typescript
export const ecrRepository = new aws.ecr.Repository('ygg-evm-indexer-repo', {
  name: appConfig.ecs.repositoryName,
  imageScanningConfiguration: { scanOnPush: true },
  encryptionConfiguration: { encryptionType: 'AES256' },
  tags: getTags({ Name: appConfig.ecs.repositoryName }),
})

// Lifecycle: keep last 10 tagged images, delete untagged after 1 day
new aws.ecr.LifecyclePolicy('ecr-lifecycle', {
  repository: ecrRepository.name,
  policy: JSON.stringify({
    rules: [
      { rulePriority: 1, selection: { tagStatus: 'untagged', countType: 'sinceImagePushed', countUnit: 'days', countNumber: 1 }, action: { type: 'expire' } },
      { rulePriority: 2, selection: { tagStatus: 'tagged', tagPrefixList: ['v'], countType: 'imageCountMoreThan', countNumber: 10 }, action: { type: 'expire' } },
    ],
  }),
})
```

## ECS on EC2

```typescript
// Cluster with Container Insights
export const ecsCluster = new aws.ecs.Cluster('ygg-ecs-cluster', {
  name: getResourceName('clusterName'),
  settings: [{ name: 'containerInsights', value: 'enabled' }],
  tags: getTags({ Name: getResourceName('clusterName') }),
})

// Auto Scaling Group: min=1, max=3
const asg = new aws.autoscaling.Group('ecs-asg', {
  launchTemplate: { id: launchTemplate.id, version: '$Latest' },
  minSize: 1,
  maxSize: 3,
  desiredCapacity: 1,
  vpcZoneIdentifiers: vpc.publicSubnetIds,
  tags: [{ key: 'AmazonECSManaged', value: 'true', propagateAtLaunch: true }],
})
```

## ECS Task Definition

```typescript
const taskDefinition = new aws.ecs.TaskDefinition('evm-indexer-task', {
  family: getResourceName('taskFamily'),
  cpu: '512',
  memory: '1024',
  networkMode: 'bridge',
  executionRoleArn: ecsExecutionRole.arn,
  taskRoleArn: ecsTaskRole.arn,
  containerDefinitions: pulumi.jsonStringify([{
    name: 'evm-indexer',
    image: pulumi.interpolate`${ecrRepository.repositoryUrl}:latest`,
    portMappings: [{ containerPort: 3000, hostPort: 0, protocol: 'tcp' }],
    environment: [
      { name: 'NODE_ENV', value: environment },
    ],
    secrets: [
      { name: 'DATABASE_URL', valueFrom: dbSecretArn },
      { name: 'REDIS_URL', valueFrom: appSecretArn },
    ],
    logConfiguration: {
      logDriver: 'awslogs',
      options: {
        'awslogs-group': '/ecs/evm-indexer-task',
        'awslogs-region': awsRegion,
        'awslogs-stream-prefix': 'ecs',
      },
    },
    healthCheck: {
      command: ['CMD-SHELL', 'curl -f http://localhost:3000/health || exit 1'],
      interval: 30,
      timeout: 5,
      retries: 3,
    },
  }]),
  tags: getTags({}),
})
```

**Rules**:
- Always inject secrets via `secrets` (Secrets Manager ARN), never `environment`
- Always configure health checks
- Always configure CloudWatch log driver
- Use `hostPort: 0` with bridge networking for dynamic port allocation

## ECS Service with Auto Scaling

```typescript
const ecsService = new aws.ecs.Service('evm-indexer-service', {
  cluster: ecsCluster.arn,
  taskDefinition: taskDefinition.arn,
  desiredCount: 1,
  launchType: 'EC2',
  tags: getTags({}),
})

// CPU-based auto scaling at 70% threshold
const scalingTarget = new aws.appautoscaling.Target('ecs-scaling-target', {
  serviceNamespace: 'ecs',
  resourceId: pulumi.interpolate`service/${ecsCluster.name}/${ecsService.name}`,
  scalableDimension: 'ecs:service:DesiredCount',
  minCapacity: 1,
  maxCapacity: 3,
})

new aws.appautoscaling.Policy('ecs-scaling-policy', {
  serviceNamespace: 'ecs',
  resourceId: scalingTarget.resourceId,
  scalableDimension: scalingTarget.scalableDimension,
  policyType: 'TargetTrackingScaling',
  targetTrackingScalingPolicyConfiguration: {
    predefinedMetricSpecification: { predefinedMetricType: 'ECSServiceAverageCPUUtilization' },
    targetValue: 70,
  },
})
```
