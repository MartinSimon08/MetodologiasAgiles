import type { ReactNode } from 'react'

interface Props {
  onClick: () => void
  disabled?: boolean
  children: ReactNode
}

export function BotonNuevo({ onClick, disabled, children }: Props) {
  return (
    <button type="button" onClick={onClick} disabled={disabled}>
      <svg
        width="18"
        height="18"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        aria-hidden="true"
      >
        <path d="M12 5v14M5 12h14" />
      </svg>
      {children}
    </button>
  )
}
