# Error Tracking

## Error Capture

```typescript
// libs/posthog/captureErrors.ts
export async function capturePosthogError(error: Error, properties: Properties) {
  const posthog = await getPostHog()
  await posthog.captureException(error, properties)
}
```

## Component Error Hook

```typescript
// hooks/analytics/useComponentError.ts
export default function useComponentError(
  error: string | Error | null | undefined,
  options: UseComponentErrorOptions,
) {
  const { sourceComponent, errorType = ERROR_TYPES.COMPONENT_ERROR, errorMessage, additionalProperties = {} } = options

  useEffect(() => {
    if (error) {
      const errorObj = new Error(`${errorType}: ${errorMessage}`)
      errorObj.name = `${errorType}: ${sourceComponent}`

      capturePosthogError(errorObj, {
        errorMessage,
        errorType,
        sourceComponent,
        ...additionalProperties,
      })
    }
  }, [error, sourceComponent, errorType, additionalProperties])
}
```

## Error Types

```typescript
export enum ERROR_TYPES {
  COMPONENT_ERROR = 'Component Error',
  API_ERROR = 'API Error',
  NETWORK_ERROR = 'Network Error',
  SERVICE_ERROR = 'Service Error',
}
```

## Automatic API Error Tracking

The API client automatically captures errors based on HTTP status:

```typescript
// libs/api-client/api-error-handler.ts
export const shouldTrackHttpError = (status: number) => {
  if (status >= 500) return true              // Server errors — always track
  if ([401, 403, 408].includes(status)) return true  // Auth/permission/timeout
  if ([400, 409, 422].includes(status)) return true  // Business logic errors
  if ([404, 429].includes(status)) return false      // Skip common noise
  return false
}
```

The API client wraps all requests and captures IN_PROGRESS → SUCCESS/ERROR with full context (status, method, domain, response body, stack trace).
