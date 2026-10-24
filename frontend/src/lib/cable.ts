import { createConsumer } from '@rails/actioncable'
import { tokenStorage } from './api'

const apiUrl = import.meta.env.VITE_API_URL ?? 'http://localhost:3000'
const cableUrl = apiUrl.replace(/^http/, 'ws') + '/cable'

export const cable = createConsumer(() => {
  const token = tokenStorage.get()
  return token ? `${cableUrl}?token=${encodeURIComponent(token)}` : cableUrl
})
