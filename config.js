// PUBLIC settings only. The anon/publishable key is safe here because database rules (RLS) protect your data.
// NEVER paste the "service_role" or "secret" key anywhere in this project.
window.BF_CONFIG = {
  SUPABASE_URL: 'YOUR_SUPABASE_URL',
  SUPABASE_ANON_KEY: 'YOUR_SUPABASE_ANON_KEY',
  WHATSAPP: 'YOUR_WHATSAPP_NUMBER', // digits only with country code, e.g. 923001234567 (no + or spaces)
  EMAIL: '' // optional public contact email
};
