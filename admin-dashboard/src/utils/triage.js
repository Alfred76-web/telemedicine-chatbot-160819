export const TRIAGE = {
  'self-care': { label: 'Self-care', color: '#2e7d32', bg: '#e8f5e9' },
  pharmacy:    { label: 'Pharmacy',  color: '#1565c0', bg: '#e3f2fd' },
  clinic:      { label: 'Clinic',    color: '#ef6c00', bg: '#fff3e0' },
  emergency:   { label: 'Emergency', color: '#c62828', bg: '#ffebee' },
};

export const triageInfo = (triage) =>
  TRIAGE[triage] || { label: triage || '—', color: '#6b7a83', bg: '#eceff1' };

export const LANGUAGE_LABELS = { en: 'English', sw: 'Kiswahili' };

export function formatDateTime(value) {
  if (!value) return '—';
  return new Date(value).toLocaleString('en-GB', {
    day: 'numeric', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  });
}