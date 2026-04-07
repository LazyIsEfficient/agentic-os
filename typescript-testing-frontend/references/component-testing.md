# Component Testing

## Basic Component Test

```typescript
import { render, screen, fireEvent } from '@/test-utils/render'
import { TaskItem } from '../TaskItem'

describe('TaskItem', () => {
  const defaultProps = {
    cta: 'Enroll',
    completed: false,
    locked: false,
    isLoading: false,
  }

  it('renders disabled button when locked', () => {
    render(<TaskItem {...defaultProps} locked={true} cta="Locked" />)
    expect(screen.getByRole('button', { name: /locked/i })).toBeDisabled()
  })

  it('renders link with href when url is provided', () => {
    render(<TaskItem {...defaultProps} url="https://example.com/play" cta="Play" />)
    const link = screen.getByRole('link', { name: /play/i })
    expect(link).toHaveAttribute('href', 'https://example.com/play')
    expect(link).toHaveAttribute('target', '_blank')
  })

  it('calls onEnroll when button clicked', () => {
    const onEnroll = jest.fn()
    render(<TaskItem {...defaultProps} onEnroll={onEnroll} />)
    fireEvent.click(screen.getByRole('button', { name: /enroll/i }))
    expect(onEnroll).toHaveBeenCalledTimes(1)
  })
})
```

## User Interactions with `userEvent`

Prefer `userEvent.setup()` over `fireEvent` for realistic user interaction simulation:

```typescript
import userEvent from '@testing-library/user-event'
import { render, screen, waitFor } from '@/test-utils/render'

describe('ProfileMenu', () => {
  it('opens menu and shows options when trigger clicked', async () => {
    const user = userEvent.setup()
    render(<ProfileMenu />)

    await user.click(screen.getByRole('button'))

    await waitFor(() => {
      expect(screen.getByText('Manage Wallet')).toBeInTheDocument()
      expect(screen.getByText('Sign Out')).toBeInTheDocument()
    })
  })

  it('calls logout when Sign Out is clicked', async () => {
    const user = userEvent.setup()
    render(<ProfileMenu />)

    await user.click(screen.getByRole('button'))
    await waitFor(() => expect(screen.getByText('Sign Out')).toBeInTheDocument())
    await user.click(screen.getByText('Sign Out'))

    expect(mockLogout).toHaveBeenCalled()
  })
})
```
